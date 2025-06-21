#!/bin/sh

architectures="x86_64"
custom="true"
ref="https://1bin.org"

_sources() {
	source_list=$(curl -Ls https://api.github.com/repos/nikvdp/1bin/releases/latest | sed 's/[()",{} ]/\n/g')
	pkg_and_dl=$(echo "$source_list " | grep -i "^http.*download*" | grep -v "/mac-")
	appnames=$(echo "$pkg_and_dl" | sed 's:.*/::' | tr '[:upper:]' '[:lower:]')
}

for arch in $architectures; do
	rm -f "$arch".md
	_sources
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app$")
		if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
			description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			if [ "$custom" != "true" ]; then
				site=$(grep "^| $app " ../descriptions.md | awk -F'|' '{print $4}' | sed 's/^ //g; s/ $//g; s/  / /g')
				[ "$site" = "None" ] && site=""
			fi
		fi
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="$ref"
		[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.*download.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
