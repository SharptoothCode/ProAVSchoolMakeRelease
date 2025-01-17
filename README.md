# ProAVSchoolMakeRelease
This repository is intended to be used as a template for the start of new projects and includes a make_release utility that I developed for my Git course.
Includes:
- folder structure with placeholder files
- .gitignore file for common Crestron development ignoring most of the compiled output and focusing on the source code
- .gitattributes file to treat .smw and .vtp as binary. Also defines .vtp as Git-LFS for optimum repo size and performance of larger binary files.
- make_release utility for release snapshots and deploy archives

To learn Git and how to use it effectively specifically with Crestron programming you can purchase my full course at https://training.proavschool.com/git
Dustin Baerg, ProAVSchool.com

# Usage Instructions
Clone this repo as a starting point for new projects.
You must remove the remote otherwise it will try to push changes of the new project back into the template. This won't work because there are no push permissions for the public repo on GitHub but you can also clone the repo locally on your machine to start new projects and that is where this is more relevant.
```
git clone [this repo url] new project directory
git remote remove origin
git commit --allow-empty -m "Start new project based on template"
```

Next, you need to rename the `rename-releases` directory to `releases`. This had to be done because we have releases in .gitignore so it wouldn't be pulled into a cloned repository.
Then you can start putting in your SIMPL and VTP files etc.

The template is a work in progress and will be adjusted over time.
Currently it has the following
- SIMPL and UI directory
- placeholder .smw and .vtp files
- rename-releases directory

## Additional Considerations
The clone method described will create a copy of this repository for a new project and it will contain all the commits and revision history of the template repo itself.
If you want no history at all and just a clean slate with the current template, do the following:

```
cd new-project
rm -rf .git
git init
git add .
git commit -m "Start new project based on template"
```

# make_release Overview
This utility uses the latest tag name from Git and creates two archives:
```
ProjectName_tagname_archive.zip
ProjectName_tagname_deploy.zip
```
So if your tag was v1.0 it would be:
```
ProjectName_v1.0_archive.zip
ProjectName_v1.0_deploy.zip
```
The archive will contain all the source files - a full snapshot of your project at the time it is run.
The deploy zip file can be distributed to technicians to load onsite. The archive can be copied to another backup location or just kept for your own reference.

The deploy file only contains files to load to the systems:
- .lpz (4 series compiled code)
- .sig (for debugging purposes)
- .vtz (touch panel file)
- .Core3 (folder for Crestron App projects)
- .ch5z (CH5/Crestron Construct projects)

Simply run make_release by double clicking it in your project’s releases folder after adding a new Git tag in Sourcetree or via other methods.
The utility uses Git to find the last tag in your repository and creates the zip files with the tag name added. 

Important: You want to ensure that you don’t make changes to any files after tagging the release before you run the make_release utility otherwise it will zip up files that aren’t specifically from that release.

## Dependancies
The utility is two files - a basic shell script and a batch file to run it.
Windows will run the .bat file directly if you double click it in file manager.

The shell script requires Git Bash to run on Windows, which is typically installed with Git on your machine.
The script also uses the zip command, which might not be available on your system. To install zip, you’ll first need to install Chocolatey, a popular package manager for Windows that simplifies software installation. https://chocolatey.org/