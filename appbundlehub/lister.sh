#!/bin/sh

architectures="x86_64"
for arch in $architectures; do
	rm -f "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	json_file=$(curl -Ls "$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*metadata_$arch-Linux.json$" | head -1)")
	pkg_and_dl=$(echo "$json_file "| grep "{\|\"pkg\"\|\"download_url\"" | sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg:/|/g; s/ download_url://g' | sort -u)
	appnames=$(echo "$pkg_and_dl" | sed 's/ | | /\n/g' | awk -F'|' '{print $2}' | sed -- 's/.dwfs.AppBundle//g; s/.sqfs.AppBundle//g; s/.AppDir//g; s/.AppBundle//g; s/-[0-9].*$//' | tr '[:upper:]' '[:lower:]')
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app.")
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
		fi
		description=$(echo "$archpage" | grep -A 2 Description: | tr '><' '\n' | grep "^[A-Z]" | sed 's/&amp\;/and/g' | tail -1)
		site=$(echo "$archpage" | grep -A 2 "Upstream URL" | tr '><' '\n' | grep "^http.*" | tail -1)
		#version=$(echo "$archpage")
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="https://xplshn.github.io/AppBundleHUB#$appname"
		[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.*download.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
