# AM-extras
***Extensions for "AM", the package manager for AppImages and portable apps for GNU/Linux***

<img width="747" height="510" alt="Istantanea_2025-08-08_13-08-17" src="https://github.com/user-attachments/assets/3063499c-9682-48a9-b305-ea7d2abe2297" />

This repository is used to extend the available AM/AppMan software portfolio by adding third-party sources to the AM database.

***To know more about AM, visit https://github.com/ivan-hc/AM***

---------------------------------
## How it works
Each database has one or more table .md with the name of the architecture that will use it.

Each table has the following format:

| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |
| program0 | Description of program0 | url-of-the-main-page | url-to-the-file | 1.5 |
| program1 | Description of program1 | url-of-the-main-page | url-to-the-file | 0.8 |

Note the spaces between one separator and another (see the code below):
```
| appname | description | source (URL) | download (URL) | version |
```

To create a table, use a script named `lister.sh`. You can check the one in each directory of this repo as an example.

**All lists available in this repository are updated every hour.**

---------------------------------
## Database name, extension and flag
Each database must have its own simple name. This will be used:
- as a flag after two dashes, in `-l`, `-q` and `-i`
- as an extension after a dot, in `-a` and `-i`
- as first word into a variable name

Given the above rules, and given a database we will call "sample":
- the flag will be `--sample`
- the extension will be `.sample`
- the variables will be called `sample_repo`, `sample_readme` and `sample_info` (see below)

---------------------------------
## Variables names
Given the "sample" database and given the three variables above:
- `sample_repo` is the main page of the database. This will be shown in `-h`/`help` and `-a`/`about`
- `sample_readme` is the .md file of the targeted architecture. **NOTE** thst "`$ARCH`" is set in AM/AppMan directly
- `sample_info` (new) is a description of the content of your database, to be shown in `-h`/`help`

These must be added in "[am-extras](https://github.com/ivan-hc/am-extras/blob/main/am-extras)".

To be used in AM/AppMan, you need also to add a flag name that can be enablec if `sample_readme` is not empty.

Given all these info, this is how lines in "am-extras" must appear for the "sample" database:
```
export sample_repo="https://github.com/NAME/PROJECT"
export sample_readme="https://raw.githubusercontent.com/ivan-hc/am-extras/main/sample/${ARCH}.md"
export sample_info="This database contains amazing software in TYPE format."
export third_party_flags="$third_party_flags --sample"
```

NOTE, `third_party_flags` is a common variable needed to collect all flags of all databases. This is enriched with new flags each time it appear exported in "am-extras".

You can test your variables also from terminal, by exporting them
![Istantanea_2025-02-24_20-44-12](https://github.com/user-attachments/assets/bd70d753-3952-48b3-a59f-20c787b21919)

---------------------------------
## Usage in AM and AppMan
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
## How to test
In APP-MANAGER (`am`) or in `appman` there is a function named `_sync_third_party_lists` that contains a line `_am_extras_sources`:
1. comment the line `_am_extras_sources` in the `_sync_third_party_lists` function
2. add your lines to the ~/.local/share/AM/am-extras file
3. run `am -l --yourdatabase` to see all available apps from your database
4. run `am -i appname.yourdatabase` or `am -i --yourdatabase appname` to install an app from your database
5. run `am -a appname.yourdatabase` to get more info about the targeted app from your database
6. if everything is ok, submit your pull request to am-extras
