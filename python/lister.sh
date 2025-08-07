#!/bin/sh

architectures="aarch64 i686 x86_64"
ref="https://python-appimage.readthedocs.io"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

source_list=$(curl -Ls https://api.github.com/repos/niess/python-appimage/releases)
[ -z "$source_list" ] && source_list=$(curl -Ls https://api.gh.pkgforge.dev/repos/niess/python-appimage/releases)
pkg_and_dl=$(echo "$source_list " | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*AppImage$")
appnames=$(echo "$pkg_and_dl" | tr '/' '\n' | grep "^python[0-9].[0-9]" | grep -vi "appimage" | uniq | sort --version-sort | xargs)

if [ -n "$source_list" ] && echo "$pkg_and_dl" | grep -qi "appimage$"; then
	for arch in $architectures; do
		echo "$header" > "$arch".md
		for app in $appnames; do
			appname="$app"
			description="Interactive high-level object-oriented language"
			site="$ref"
			download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app/.*$arch.*")
			version=$(echo "$download" | tr '/-' '\n' | grep "^python[0-9].[0-9]" | tail -1 | sed 's/python//g')
			for d in $download; do
				if echo "| $appname | $description | $site | $d | $version |" | grep -qi "^| .* | .* | http.* | http.*download.* | .* |$"; then
					series=$(echo "$d" | sed 's:.*/::' | tr '.-' '\n' | grep -i "^cp\|^manylinux" | xargs | tr ' ' '-')
					echo "| $appname | $description | $site/.../$appname-$series | $d | $version |" >> "$arch".md
				fi
			done
			unset appname description site download	version series
		done
	done
fi
