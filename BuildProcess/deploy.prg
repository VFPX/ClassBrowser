*******************************************************************************
* Deploy.prg does the deployment steps necessary to update the files needed by
* Thor Check For Updates (CFU). This PRG is expected to be in a subdirectory of
* the project root folder named BuildProcess. Other files that need to be in
* this subdirectory are:

* - InstalledFiles.txt: contain the paths for the files to be installed by Thor
* 	CFU, one file per line. Paths relative to the root of the project folder
*	should be used. Alternatively, manually create a subdirectory of the
*	project root folder named InstalledFiles and copy the necessary files into
*	that folder (only the files to be installed; no extra stuff allowed).

* - ProjectSettings.txt: contains the project settings:
*		appName      = descriptive name of the project (required)
*		appID        = project name (usually the descriptive name but cannot
*						contain spaces; required)
*		majorVersion = version number (optional; see below)
*		versionDate  = release date as YYYY-MM-DD (optional; see below)
*		prompt       = Y to prompt for majorVersion if it isn't specified;
*						N to not prompt. Not required if majorVersion is
*						specified
*		changeLog    = path for a file containing changes (optional; see below)
*	For example:
*		appName      = Project Explorer
*		appID        = ProjectExplorer
*		majorVersion = 1.0
*		versionDate  = 2023-01-07
*		changeLog    = Change Log.md
*
*	These values are store in public variables:
*		pcAppName: the appName setting
*		pcAppID: the appID setting
*		pcMajorVersion: the major version number
*		pdVersionDate: the release date
*		pcVersionDate: the release date as 'YYYY-MM-DD'
*		pcChangeLog: the path for the change log
*
*	Note that only appName and appID are required. For the other settings:
*		- majorVersion: you can either edit Project.txt and update majorVersion
*			before running Deploy.prg or omit it from Project.txt, in which
*			case you'll be prompted for a value if the prompt setting is Y or
*			omitted. If the prompt setting is N, that means your Build.prg
*			(see below) will update the pcMajorVersion variable with the
*			version number (for example, by reading from an INI file or source
*			code).
*		- versionDate: you can either edit Project.txt and update versionDate
*			before running Deploy.prg or omit it from Project.txt, in which
*			case today's date is used.

* - VersionTemplate.txt: contains a template for the Thor CFU version file.
*	Although it has a TXT extension, it actually contains VFP code. It must
*	accept a single parameter, which is a Thor CFU updater object. The code
*	will typically set properties of that object to do whatever is necessary.
*	This template file should have placeholders for project settings:
*		- {MAJORVERSION}: substituted with the value of pcMajorVersion
*		- {VERSIONDATE}: substituted with the value of pdVersionDate
*		- {APPNAME}: substituted with the value of pcAppName
*		- {APPID}: substituted with the value of pcAppID
*		- {JULIAN}: substituted with the value of pdVersionDate as a numeric
*			value: the Julian date since 2000-01-01 (some projects use that as
*			a minor version number)
*		- {CHANGELOG}: substituted with the contents of the file specified in
*			pcChangeLog

*** TODO: point them to docs for what a Thor CFU version file might contain

* - Build.prg: an optional program that performs any build tasks necessary for
*	the project, such as building an APP, updating versions numbers in code or
*	include files, etc. This program can use the public variables discussed
*	above.

*** TODO: document conversion process: create BuildProcess folder, move Project.txt from ThorUpdater
*** and rename to ProjectSettings.txt, move Version.txt from ThorUpdater and rename to VersionTemplate.txt
*** copy Deploy.prg to BuildProcess, create Build.prg if desired

*******************************************************************************

* Start by making sure the current folder is the root for the project (one
* level up from the location of this PRG).

lcProgram    = sys(16)
lcCurrFolder = addbs(justpath(lcProgram))
lcFolder     = fullpath('..\', lcCurrFolder)
cd (lcFolder)

* Put the paths for files we may use into variables.

lcProjectFile           = lcCurrFolder + 'ProjectSettings.txt'
lcInstalledFilesListing = lcCurrFolder + 'InstalledFiles.txt'
lcInstalledFilesFolder  = 'InstalledFiles'
lcBuildProgram          = lcCurrFolder + 'BuildMe.prg'
lcVersionTemplateFile   = lcCurrFolder + 'VersionTemplate.txt'

* Give a warning and exit if ProjectSettings.txt or VersionTemplate.txt don't exist.

if not file(lcProjectFile)
	messagebox('Please create ProjectSettings.txt in the BuildProcess ' + ;
		'folder.', 16, 'Project Deployment')
	return
endif not file(lcProjectFile)
if not file(lcVersionTemplateFile)
	messagebox('Please create VersionTemplate.txt in the BuildProcess ' + ;
		'folder.', 16, 'Project Deployment')
	return
endif not file(lcVersionTemplateFile)

* Get the current project settings into public variables.

lcProjectSettings = filetostr(lcProjectFile)
public pcAppName, pcAppID, pcMajorVersion, pdVersionDate, pcVersionDate, pcChangeLog
pdVersionDate  = date()
pcMajorVersion = ''
pcChangeLog    = ''
llPrompt       = .T.
lnSettings     = alines(laSettings, lcProjectSettings)
for lnI = 1 to lnSettings
	lcLine  = laSettings[lnI]
	lnPos   = at('=', lcLine)
	lcName  = alltrim(left(lcLine, lnPos - 1))
	lcValue = alltrim(substr(lcLine, lnPos + 1))
	lcUName = upper(lcName)
	do case
		case lcUName = 'APPNAME'
			pcAppName = lcValue
		case lcUName = 'APPID'
			pcAppID = lcValue
		case lcUName = 'MAJORVERSION'
			pcMajorVersion = lcValue
		case lcUName = 'VERSIONDATE'
			pdVersionDate = evaluate('{^' + lcValue + '}')
		case lcUName = 'PROMPT'
			llPrompt = upper(lcValue) = 'Y'
		case lcUName = 'CHANGELOG'
			pcChangeLog = lcValue
	endcase
next lnI

lcDate    = dtoc(pdVersionDate, 1)
pcVersionDate = Substr(lcDate, 1, 4) + '-' + Substr(lcDate, 5, 2) + '-' + Substr(lcDate, 7, 2)
* Ensure we have valid pcAppName and pcAppID values.

if empty(pcAppName)
	messagebox('The appName setting was not specified.', 16, ;
		'Project Deployment')
	return
endif empty(pcAppName)
if empty(pcAppID)
	messagebox('The appID setting was not specified.', 16, ;
		'Project Deployment')
	return
endif empty(pcAppID)
if ' ' $ pcAppID
	messagebox('The appID setting cannot have spaces.', 16, ;
		'Project Deployment')
	return
endif ' ' $ pcAppID

* Get the names of the zip and Thor CFU version files.

lcZipFile     = 'ThorUpdater\' + pcAppID + '.zip'
lcVersionFile = 'ThorUpdater\' + pcAppID + 'Version.txt'

* Get the major version number if it wasn't specified and we're supposed to.

if empty(pcMajorVersion) and llPrompt
	lcValue = inputbox('Major version', 'Project Deployment', '')
	if empty(lcValue)
		return
	endif empty(lcValue)
	pcMajorVersion = lcValue
endif empty(pcMajorVersion) ...

* Execute Build.prg if it exists.

if file(lcBuildProgram)
	do (lcBuildProgram)
endif file(lcBuildProgram)

* Ensure we have a major version number (Build.prg may have set it).

if empty(pcMajorVersion)
	messagebox('The majorVersion setting was not specified.', 16, ;
		'Project Deployment')
	return
endif empty(pcMajorVersion)
do case

* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).

	case file(lcInstalledFilesListing)
		lcFiles = filetostr(lcInstalledFilesListing)
		lnFiles = alines(laFiles, lcFiles)
		for lnI = 1 to lnFiles
			lcSource = laFiles[lnI]
			lcTarget = addbs(lcInstalledFilesFolder) + lcSource
			lcFolder = justpath(lcTarget)
			if not directory(lcFolder)
				md (lcFolder)
			endif not directory(lcFolder)
			copy file (lcSource) to (lcTarget)
		next lnI

* If the InstalledFiles folder doesn't exist, give a warning and exit.

	case not directory(lcInstalledFilesFolder)
		messagebox('Please either create InstalledFiles.txt in the ' + ;
			'BuildProcess folder with each file to be installed by Thor ' + ;
			'listed on a separate line, or create folder named ' + ;
			'InstalledFiles with the files Thor should install.', ;
			16, 'Project Deployment')
		return
endcase

* Update Version.txt.

lcDate    = dtoc(pdVersionDate, 1)
lcVersion = filetostr(lcVersionTemplateFile)
lnJulian  = val(sys(11, pdVersionDate)) - val(sys(11, {^2000-01-01}))
lcJulian  = padl(transform(lnJulian), 4, '0')
lcChange  = iif(file(pcChangeLog), filetostr(pcChangeLog), '')
lcVersion = strtran(lcVersion, '{APPNAME}',      pcAppName,      -1, -1, 1)
lcVersion = strtran(lcVersion, '{APPID}',        pcAppID,        -1, -1, 1)
lcVersion = strtran(lcVersion, '{VERSIONDATE}',  lcDate,         -1, -1, 1)
lcVersion = strtran(lcVersion, '{MAJORVERSION}', pcMajorVersion, -1, -1, 1)
lcVersion = strtran(lcVersion, '{JULIAN}',       lcJulian,       -1, -1, 1)
lcVersion = strtran(lcVersion, '{CHANGELOG}',    lcChange,       -1, -1, 1)
strtofile(lcVersion, lcVersionFile)

* Execute the PowerShell command to create the zip file. Although it's the
* obvious choice, we don't use VFPCompression.fll to do this because it has a
* bug that prevents it from creating a valid zip file under some conditions.

*** TODO: don't hard-code path to powershell.exe?
lcCommand = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ' + ;
	'Compress-Archive ' + ;
	'-Path ' + lcInstalledFilesFolder + '\* ' + ;
	'-DestinationPath ' + lcZipFile
erase (lcZipFile)
run &lcCommand

* Restore the former current directory.

cd (lcCurrFolder)
