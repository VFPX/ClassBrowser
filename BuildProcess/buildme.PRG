Local lcVersionFile, lcVersionText

lcVersionFile = 'Browser\Version.h'
Erase (m.lcVersionFile)

lcVersionText = Textmerge('#DEFINE VERSION_NUMBER "Ver <<pcVersion>> : <<pcVersionDate>>"')
Strtofile(m.lcVersionText, m.lcVersionFile)

Build App 'InstalledFiles\BROWSER' From 'Browser\BROWSER.pjx' 
