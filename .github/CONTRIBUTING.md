# How to contribute to ClassBrowser

## Bug report?
- Please check [issues](https://github.com/VFPX/ClassBrowser/issues) if the bug is reported
- If you're unable to find an open issue addressing the problem, open a new one. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

### Did you write a patch that fixes a bug?
- Open a new GitHub merge request with the patch.
- Ensure the PR description clearly describes the problem and solution.
  - Include the relevant version number if applicable.
- See [New version](#new-version) for additional tasks

## New version
Here are the steps to updating to a new version:

1. Create a fork at github
   - See this [guide](https://www.dataschool.io/how-to-contribute-on-github/) for setting up and using a fork
1. Make whatever changes are necessary.
---
3. In folder _Browser_
   - Update the version number and date at the top of  _Browser.h_
   - Run FoxBin2Prg to create the text files:
        - `DO foxbin2prg.prg WITH 'BIN2PRG','*.*'`
   - Run _BuildBrowser.prg_ to create the App.
3. Update the version and date in the top few lines and at the very bottom of _ReadMe.md_ 
3. Describe the changes in the top of _Change Log.md_.
3. In folder _ThorUpdater_:
    - Edit the majorVersion and versionDate settings in _Project.txt_
    - Right-click _CreateThorUpdate.ps1_ and select **Run with PowerShell** from the shortcut menu to re-create _ClassBrowserVersion.txt_ and _ClassBrowser.zip_
---
7. Commit
8. Push to your fork
8. Create a pull request

----
Last changed: _2023-01-07_
![Picture](../Docs/Images/vfpxpoweredby_alternative.gif)