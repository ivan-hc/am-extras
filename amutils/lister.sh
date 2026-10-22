#!/bin/sh

architectures="aarch64 x86_64"
ref="https://github.com/ivan-hc/am-utils"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

source_list=$(curl -Ls https://api.github.com/repos/ivan-hc/am-utils/releases)
[ -z "$source_list" ] && source_list=$(curl -Ls https://api.gh.pkgforge.dev/repos/ivan-hc/am-utils/releases)
pkg_and_dl=$(echo "$source_list " | sed 's/[()",{} ]/\n/g' | grep -Eoi -- "https.*download.*_[0-9].*-static$")
appnames=$(awk '{print $2}' ./list | sort -u | xargs)

if [ -n "$source_list" ] && echo "$pkg_and_dl" | grep -qi -- "-static$"; then
	for arch in $architectures; do
		echo "$header" > "$arch".md
		for app in $appnames; do
			appname="$app"
			description=$(grep "^◆ $app : " ./list 2>/dev/null | sed "s/^◆ $app : //g")
			[ -z "$description" ] && description="No description available"
			site="$ref"
			app=$(echo "$app" | sed 's/\+/\%2b/g')
			download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -Eoi -- "https.*download.*/$arch-[0-9]{8}/${app}_.*-$arch-static$" | head -1)
			version=$(echo "$download" | sed 's:.*/::' | grep -oP '(?<=-)([0-9]+\.?)+' | sed 's/ //g' | head -1)
			[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
			if echo "| $appname | $description | $site | $download | $version |" | grep -qi "^| .* | .* | http.* | http.*download.* | .* |$"; then
				echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
			fi
			unset appname description site download	version
		done
	done
fi
