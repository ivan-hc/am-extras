#!/bin/sh

architectures="x86_64"
custom="true"
ref="https://xplshn.github.io/AppBundleHUB"

_sources() {
	source_list=$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases/latest)
	pkg_and_dl=$(echo "$source_list " | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*AppBundle$")
	appnames=$(echo "$pkg_and_dl" | sed 's:.*/::' | sed -- 's/.dwfs.AppBundle//g; s/.sqfs.AppBundle//g; s/.AppDir//g; s/.AppBundle//g; s/-[0-9].*$//; s/-v[0-9].*$//' | tr '[:upper:]' '[:lower:]')
}

for arch in $architectures; do
	_sources
	[ -z "$source_list" ] && exit 1
	rm -f "$arch".md
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app.")
		if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
			description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			if [ "$custom" != "true" ]; then
				site=$(grep "^| $app " ../descriptions.md | awk -F'|' '{print $4}' | sed 's/^ //g; s/ $//g; s/  / /g')
				[ "$site" = "None" ] && site=""
			fi
		fi
		version=$(echo "$download" | sed 's:.*/::' | grep -oP '(?<=-)([0-9]+\.?)+' | sed 's/ //g' | head -1)
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="$ref#$appname"
		[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.*download.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
