**Extensions for "[AM](https://github.com/ivan-hc/AM)", the package manager for AppImages and portable apps for GNU/Linux**

## Usage

To be valid, a list must have these references
```
| appname | description | source (URL) | download (URL) | version |
```
Note the spaces between one separator and another.

Each directory of this repository has a script called `lister.sh` to generate this table.

The tables are used by the "[AM](https://github.com/ivan-hc/AM)" package manager to generate the lists, download the applications and get more information about each app available in that database.

To add new databases, the two variables ending with _repo and _readme must start with the name of the database, and a flag in `$third_party_flags` must be added.

Optionally you can add a third variable for the description to be displayed while running `am -h`, with the database name and ending with _info

For example, where "`sample`" is the name of your database... simply export the following variables:
```
export sample_repo="https://github.com/NAME/PROJECT"
export sample_readme="https://raw.githubusercontent.com/ivan-hc/am-extras/main/sample/${ARCH}.md"
export sample_info="This database contains amazing software"
export third_party_flags="$third_party_flags --sample"
```
![Istantanea_2025-02-24_20-44-12](https://github.com/user-attachments/assets/bd70d753-3952-48b3-a59f-20c787b21919)

Each database will automatically have its own flag and extension.

**All lists available in this repository are updated every hour.**
