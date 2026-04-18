#!/bin/sh

architectures="x86_64 i686 aarch64"
site="https://github.com/Samueru-sama/coreutils-sh"
version=$(curl -Ls https://github.com/Samueru-sama/coreutils-sh/tree/main/bin | tr '{}' '\n' | grep "currentOid" | tr '">< ' '\n' | grep . | tail -1 | cut -c -7)

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

_sources() {
	source_list=$(curl -Ls "https://github.com/Samueru-sama/coreutils-sh/tree/main/bin")
	pkg_and_dl=$(echo "$source_list " | tr '">< ' '\n' | grep -i "^bin/" | sed "s#^#https://raw.githubusercontent.com/Samueru-sama/coreutils-sh/refs/heads/main/#g" | grep -v "\[")
	appnames=$(echo "$pkg_and_dl"  | sed 's:.*/::' )
}

for arch in $architectures; do
	printf '%s\n' "$header" > "$arch".md
	_sources
	for app in $appnames; do
		appname=$( echo "$app" | tr '_' '-')
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*/$app$")
		if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
			description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			[ -z "$description" ] && description="No description available"
		fi
		[ -z "$description" ] && description="No description available"
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
	done
done
