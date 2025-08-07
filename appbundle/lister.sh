#!/bin/sh

architectures="x86_64"
ref="https://xplshn.github.io/AppBundleHUB"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

source_list=$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases/latest)
[ -z "$source_list" ] && source_list=$(curl -Ls https://api.gh.pkgforge.dev/repos/xplshn/AppBundleHUB/releases/latest)
pkg_and_dl=$(echo "$source_list " | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*AppBundle$")
appnames=$(echo "$pkg_and_dl" | sed 's:.*/::' | sed -- 's/.dwfs.AppBundle//g; s/.sqfs.AppBundle//g; s/.AppDir//g; s/.AppBundle//g; s/-[0-9].*$//; s/-v[0-9].*$//' | tr '[:upper:]' '[:lower:]')

if [ -n "$source_list" ] && echo "$pkg_and_dl" | grep -qi "appbundle$"; then
	for arch in $architectures; do
		echo "$header" > "$arch".md
		for app in $appnames; do
			appname="$app"
			if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
				description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
				[ -z "$description" ] && description="No description available"
			fi
			site="$ref"
			download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app.")
			version=$(echo "$download" | sed 's:.*/::' | grep -oP '(?<=-)([0-9]+\.?)+' | sed 's/ //g' | head -1)
			[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
			if echo "| $appname | $description | $site | $download | $version |" | grep -qi "^| .* | .* | http.* | http.*download.* | .* |$"; then
				echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
			fi
			unset appname description site download	version
		done
	done
fi
