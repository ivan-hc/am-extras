**Extensions for "[AM](https://github.com/ivan-hc/AM)", the package manager for AppImages and portable apps for GNU/Linux**

## Usage

To be valid, a list must have these references
```
| appname | description | source (URL) | download (URL) | version |
```
Note the spaces between one separator and another.

Each directory of this repository has a script called `lister.sh` to generate this table.

The tables are used by the "[AM](https://github.com/ivan-hc/AM)" package manager to generate the lists, download the applications and get more information about each app available in that database.

To add new databases, simply add two variables that start with the generic name of the database and end with _repo and _readme to [APP-MANAGER](https://github.com/ivan-hc/AM/blob/main/APP-MANAGER), for example:
```
- sample_repo="https://github.com/NAME/PROJECT"
- sample_readme="https://raw.githubusercontent.com/ivan-hc/am-extras/main/sample/${ARCH}.md"
```
Each database will automatically have its own flag and extension.
