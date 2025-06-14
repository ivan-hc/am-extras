#!/bin/sh

architectures="i686 x86_64"
custom="false"
ref="https://busybox.net"

_sources() {
	source_list=$(curl -Ls "https://github.com/ivan-hc/busybox-tools/tree/main/$arch-binaries")
	pkg_and_dl=$(echo "$source_list " | tr '">< ' '\n' | grep "^busybox_[A-Z]" | sed 's#^#https://raw.githubusercontent.com/ivan-hc/busybox-tools/refs/heads/main/x86_64-binaries/#g')
	appnames=$(echo "$pkg_and_dl" | sed 's:.*/::; s/^busybox_//g; s/-/\n/g' | grep "^[A-Z]" | tr '[:upper:]' '[:lower:]')
}

for arch in $architectures; do
	rm -f "$arch".md
	_sources
	for app in $appnames; do
		appname="$app"
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*/busybox_$app$")
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
		[ -z "$site" ] && site="$ref"
		[ -z "$version" ] && version=$(curl -Ls https://raw.githubusercontent.com/ivan-hc/busybox-tools/refs/heads/main/version)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
