#!/bin/sh

architectures="x86_64"
custom="true"
ref="https://1bin.org"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

source_list=$(curl -Ls https://api.github.com/repos/nikvdp/1bin/releases/latest | sed 's/[()",{} ]/\n/g')
[ -z "$source_list" ] && source_list=$(curl -Ls https://api.gh.pkgforge.dev/repos/nikvdp/1bin/releases/latest | sed 's/[()",{} ]/\n/g')
pkg_and_dl=$(echo "$source_list " | grep -i "^http.*download*" | grep -v "/mac-")
appnames=$(echo "$pkg_and_dl" | sed 's:.*/::' | tr '[:upper:]' '[:lower:]')

if [ -n "$source_list" ] && echo "$pkg_and_dl" | grep -qi "1bin"; then
	for arch in $architectures; do
		echo "$header" > "$arch".md
		for app in $appnames; do
			appname="$app"
			if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
				description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
				[ -z "$description" ] && description="No description available"
			fi
			site="$ref"
			download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app$")
			version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
			if echo "| $appname | $description | $site | $download | $version |" | grep -qi "^| .* | .* | http.* | http.*download.* | .* |$"; then
				echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
			fi
			unset appname description site download	version
		done
	done
fi
