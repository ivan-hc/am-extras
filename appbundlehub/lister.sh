#!/bin/sh

architectures="x86_64"
custom="true"
ref="https://xplshn.github.io/AppBundleHUB"

_sources() {
	source_list=$(curl -Ls "$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*metadata_$arch-Linux.json$" | head -1)")
	pkg_and_dl=$(echo "$source_list " | grep "{\|\"pkg\"\|\"download_url\"" | sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg:/|/g; s/ download_url://g' | sort -u)
	appnames=$(echo "$pkg_and_dl" | sed 's/ | | /\n/g' | awk -F'|' '{print $2}' | sed -- 's/.dwfs.AppBundle//g; s/.sqfs.AppBundle//g; s/.AppDir//g; s/.AppBundle//g; s/-[0-9].*$//' | tr '[:upper:]' '[:lower:]')
}

for arch in $architectures; do
	rm -f "$arch".md
	_sources
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app.")
		if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
			description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			if [ "$custom" != "true" ]; then
				site=$(grep "^| $app " ../descriptions.md | awk -F'|' '{print $4}' | sed 's/^ //g; s/ $//g; s/  / /g')
				[ "$site" = "None" ] && site=""
			fi
		else
			# Determine Arch Linux web page
			if curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"/ | grep -q "Description:"; then
				archpage=$(curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"/)
			elif curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"-desktop/ | grep -q "Description:"; then
				archpage=$(curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"-desktop/)
			elif curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"/ | grep -q "Description:"; then
				archpage=$(curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"/)
			elif curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"-desktop/ | grep -q "Description:"; then
				archpage=$(curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"-desktop/)
			elif curl -Ls https://aur.archlinux.org/packages/"$app" | grep -q "Description:"; then
				archpage=$(curl -Ls https://aur.archlinux.org/packages/"$app")
			elif curl -Ls https://aur.archlinux.org/packages/"$app"-git | grep -q "Description:"; then
				archpage=$(curl -Ls https://aur.archlinux.org/packages/"$app"-git)
			elif curl -Ls https://man.archlinux.org/man/"$app" | grep -q "DESCRIPTION"; then
				archpage=$(curl -Ls https://man.archlinux.org/man/"$app")
			fi
			if echo "$archpage" | grep -q "DESCRIPTION"; then
				description=$(echo "$archpage" | grep -A 2 NAME 2>/dev/null | grep "^<p " | head -1 | sed 's#</p>$##g' | tr '>' '\n' | tail -1 | cut -d" "  -f3-)
				[ -n "$description" ] && description=$(echo "$description" | sed 's/.*/\u&/')
				[ "$custom" != "true" ] && site=$(echo "$archpage" | grep -A 2 Upstream 2>/dev/null | tr '">< ' '\n' | grep -i "^http\|^ftp" | head -1)
				#version=$(echo "$archpage" | grep -A 1 Version 2>/dev/null | grep "<dd>" | tr '">< ' '\n' | grep "^[0-9]" | tail -1)
			else
				description=$(echo "$archpage" | grep -A 2 Description: | tr '><' '\n' | grep "^[A-Z]" | sed 's/&amp\;/and/g' | tail -1)
				[ "$custom" != "true" ] && site=$(echo "$archpage" | grep -A 2 "Upstream URL" | tr '><' '\n' | grep "^http.*" | tail -1)
				#version=$(echo "$archpage")
			fi
		fi
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
