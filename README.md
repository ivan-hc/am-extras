# AM-extras

<div align="center">

***Extensions for "AM", the package manager for AppImages and portable apps for GNU/Linux***

<p align="center">
  <img width="700" height="450" alt="Istantanea_2025-12-03_04-58-28" src="https://github.com/user-attachments/assets/fdd0eb45-00f4-4a1e-80db-cbe8d50eab90" />
</p>

This repository is used to extend the available AM/AppMan software portfolio by adding third-party sources to the AM database.

</div>


***To know more about AM, visit https://github.com/ivan-hc/AM***

---------------------------------

# Main index
- [How to create a database for AM](#how-to-create-a-database-for-am)

  - [How to set up the lister.sh script](#how-to-set-up-the-listersh-script)
  - [Why AM/AppMan needs a markdown table to handle Third-party apps](#why-amappman-needs-a-markdown-table-to-handle-third-party-apps)
 
- [How AM/AppMan uses these tables](#how-amappman-uses-these-tables)
- [How to add and use a new database in AM/AppMan](#how-to-add-and-use-a-new-database-in-amappman)

  - [How to test](#how-to-test)
 
- [How to test or use databases not in this repository](#how-to-test-or-use-databases-not-in-this-repository)

---------------------------------
# How to create a database for AM
Each directory in the root of this repository contains a script named "lister.sh" that generates a Markdown table in its same directory.

## How to set up the lister.sh script
It is a shell script that must create a table .md whit the name of the architecture, in this format:

| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |
| program0 | Description of program0 | url-of-the-main-page | url-to-the-file | 1.5 |
| program1 | Description of program1 | url-of-the-main-page | url-to-the-file | 0.8 |

Note the spaces between one separator and another (see the code below):
```
| appname | description | source (URL) | download (URL) | version |
```

You can check the lister.sh script in each directory of this repo as an example.

**All lists available in this repository are updated every hour trough Github Actions.**

## Why AM/AppMan needs a markdown table to handle Third-party apps
Given the table above, AM and AppMan will use `awk` to detect the item, in the following order:
1. `appname` is the name of the program, used in all interested options
2. `description` is the description of this app and is used in when AM/AppMan crates the lists to be used in `-l`/`list` and `-q`/`query`
3. `site` can be both the homepage of the project, the url of the database or an unique URL, also a fake one, in case there are multiple `appname` with the same name in the same table. For the latters, the option `-i`/`install` will use the multiple values of `site` to prompt a list from where you can pick one. We call them "families"
4. `download` is the direct download URL of the program. In the installation script and in the AM-updater, `awk` uses it to download the file, when `version` is changed
5. `version` is the version of the program or the releases (all depends on the targeted database), and it is used in the AM-updater to compare online and offline versions. If they are different, `download` will be called to replace the existing program

In [APP-MANAGER](https://github.com/ivan-hc/AM/blob/main/APP-MANAGER) (core script of AM/AppMan), each of these numbered columns is represented by one of these variables
```
export awk_name="1" awk_description="2" awk_site="3" awk_dl="4" awk_ver="5"
```

---------------------------------

# How AM/AppMan uses these tables
Each database must have its own simple name. This will be used:
- as a flag after two dashes, in `-l`, `-q` and `-i`
- as an extension after a dot, in `-a` and `-i`
- as first word into a variable name

Given the above rules, and given a database we will call "sample":
- the flag will be `--sample`
- the extension will be `.sample`
- the variables will be called `sample_repo`, `sample_readme` and `sample_info` (see below)
  - `sample_repo` is the main page of the database. This will be shown in `-h`/`help` and `-a`/`about`
  - `sample_readme` is the .md file of the targeted architecture. **NOTE** thst "`$ARCH`" is set in AM/AppMan directly
  - `sample_info` (new) is a description of the content of your database, to be shown in `-h`/`help`

---------------------------------

# How to add and use a new database in AM/AppMan
Once that you have added the new database directory in this repo with its own lister.sh script and its generated table .md, add the following line to the [am-extras](https://github.com/ivan-hc/am-extras/blob/main/am-extras)" script in the root of this repository, in the right space.

Where `set_db` is the name of the function that generates the database-sppecific variable names that AM/AppMan will use, `yourdbname` is the name of your database, an URL to the main site/source and a description of what the database provides:
```
set_db yourdbname "URL" "DESCRIPTION"
```
This will be a one-line command that looks like this:
```
set_db sample "https://sample.source.org" "The description of what this database provides, for example static binaries or Appimages."
```

---------------------------------

## How to test
In APP-MANAGER (`am`) or in `appman` there is a function named `_sync_third_party_lists` that contains a line `_am_extras_sources`:
1. comment the line `_am_extras_sources` in the `_sync_third_party_lists` function
2. add your lines to the ~/.local/share/AM/am-extras file
3. run `am -l --yourdatabase` to see all available apps from your database
4. run `am -i appname.yourdatabase` or `am -i --yourdatabase appname` to install an app from your database
5. run `am -a appname.yourdatabase` to get more info about the targeted app from your database
6. if everything is ok, submit your pull request to am-extras

---------------------------------

# How to test or use databases not in this repository
Given all these info, it is enough to create the variable names. For example, this is how lines would appear for the "sample" database:
```
export sample_repo="https://github.com/NAME/PROJECT"
export sample_readme="https://raw.githubusercontent.com/ivan-hc/am-extras/main/sample/${ARCH}.md"
export sample_info="This database contains amazing software in TYPE format."
export third_party_flags="$third_party_flags --sample"
```

NOTE, `third_party_flags` is a common variable needed to collect all flags of all databases. This is enriched with new flags each time it appear exported in "am-extras".

You can test your variables also from terminal, by exporting them
![Istantanea_2025-02-24_20-44-12](https://github.com/user-attachments/assets/bd70d753-3952-48b3-a59f-20c787b21919)

 If you want, you can add them to your bashrc, if you have one.

 But the simpler way is to submit it to this repository, so the `am-extras` script will handle it for you.

------------------------------------------------------------------------

###### *You can support me and my work on [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) and [**PayPal.me**](https://paypal.me/IvanAlexHC). Thank you!*

--------

*© 2020-present Ivan Alessandro Sala aka 'Ivan-HC'* - I'm here just for fun! 

------------------------------------------------------------------------

| [**ko-fi.com**](https://ko-fi.com/IvanAlexHC) | [**PayPal.me**](https://paypal.me/IvanAlexHC) | [Install "AM"/"AppMan"](https://github.com/ivan-hc/AM) | ["Main Index"](#main-index) |
| - | - | - | - |

------------------------------------------------------------------------
