#!/bin/sh

architectures="x86_64"
ref="https://github.com/ivan-hc/GNOME3-appimages"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

source_list=$(curl -Ls https://api.github.com/repos/ivan-hc/GNOME3-appimages/releases)
[ -z "$source_list" ] && source_list=$(curl -Ls https://api.gh.pkgforge.dev/repos/ivan-hc/GNOME3-appimages/releases)
pkg_and_dl=$(echo "$source_list " | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*AppImage$")
appnames=$(echo "$pkg_and_dl" | grep -oP '(?<=/download/)[^/]+' | sort -u | xargs)

if [ -n "$source_list" ] && echo "$pkg_and_dl" | grep -qi "appimage$"; then
	for arch in $architectures; do
		echo "$header" > "$arch".md
		for app in $appnames; do
			appname="$app"
			if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
				description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			fi
			[ -z "$description" ] && description="No description available"
			site="$ref"
			download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app/.*$arch.*")
			version=$(echo "$download" | grep "$app" | grep -oP '(?<=_)[0-9.]+-[0-9]+(?=-x86_64\.AppImage)')
			if echo "| $appname | $description | $site | $download | $version |" | grep -qi "^| .* | .* | http.* | http.*download.* | .* |$"; then
				echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
			fi
			unset appname description site download	version series
		done
	done
fi
