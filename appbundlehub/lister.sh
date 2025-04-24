#!/bin/sh

architectures="x86_64"
for arch in $architectures; do
	rm -f "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	json_file=$(curl -Ls "$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*metadata_$arch-Linux.json$" | head -1)")
	pkg_and_dl=$(echo "$json_file "| grep "{\|\"pkg\"\|\"download_url\"" | sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg:/|/g; s/ download_url://g' | sort -u)
	appnames=$(echo "$pkg_and_dl" | sed 's/ | | /\n/g' | awk -F'|' '{print $2}' | sed 's/.dwfs.AppBundle//g; s/.AppDir//g; s/.AppBundle//g' | tr '[:upper:]' '[:lower:]')
	for app in $appnames; do
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*download.*/$app.")
		echo "| $app | $description | $site | $download | $version |" >> "$arch".md
	done
	list=$(sort -u "$arch".md | grep "^|")
	printf "| appname | description | site | download | version |\n%b" "$list" > "$arch".md
done
