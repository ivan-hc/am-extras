#!/bin/sh

architectures="x86_64"
for arch in $architectures; do
	rm -f "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	json_file=$(curl -Ls https://api.github.com/repos/nikvdp/1bin/releases/latest | sed 's/[()",{} ]/\n/g')
	pkg_and_dl=$(echo "$json_file " | grep -i "^http.*download*" | grep -v "/mac-")
	appnames=$(echo "$pkg_and_dl" | sed 's:.*/::' | tr '[:upper:]' '[:lower:]')
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app$")
		if [ -f ../descriptions.md ] && grep -q "| $app |" ../descriptions.md; then
			description=$(grep "^| $app |" ../descriptions.md | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g')
			#site=$(grep "^| $app " ../descriptions.md | awk -F'|' '{print $4}' | sed 's/^ //g; s/ $//g; s/  / /g')
			#[ "$site" = "None" ] && site=""
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
				#site=$(echo "$archpage" | grep -A 2 Upstream 2>/dev/null | tr '">< ' '\n' | grep -i "^http\|^ftp" | head -1)
				#version=$(echo "$archpage" | grep -A 1 Version 2>/dev/null | grep "<dd>" | tr '">< ' '\n' | grep "^[0-9]" | tail -1)
			else
				description=$(echo "$archpage" | grep -A 2 Description: | tr '><' '\n' | grep "^[A-Z]" | sed 's/&amp\;/and/g' | tail -1)
				#site=$(echo "$archpage" | grep -A 2 "Upstream URL" | tr '><' '\n' | grep "^http.*" | tail -1)
				#version=$(echo "$archpage")
			fi
		fi
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="https://1bin.org"
		[ -z "$version" ] && version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.*download.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
