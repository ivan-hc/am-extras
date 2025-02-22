#!/bin/sh

architectures="x86_64 aarch64"
for arch in $architectures; do
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	curl -Ls "https://github.com/pkgforge/bincache/releases/download/metadata/$arch-Linux.json" | jq '.' \
		| grep "{\|\"pkg_name\"\|\"description\"\|\"pkg_webpage\"\|\"download_url\"\|\"version\"" \
		| sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg_name:/|/g' | sort -u \
		| sed 's/description:/ | /g; s/pkg_webpage:/ | /g; s/download_url:/ | /g; s/version:/ | /g; s/  / /g; s/  / /g' \
		| sed 's/| |/|/g' | awk -F'|' '{print $1 $2 $4 $3 $6 $5}' | sed 's/  / | /g; s/^/|/g; s/$/|/g' \
		| grep -v "| |\|||\||[a-zA-Z0-9]" >> "$arch".md
	appnames=$(awk -F'|' '{print $2}' "$arch".md | grep -v -- "appname\|---" | tr ' ' '-' | sed -- 's/^-//g; s/-$//g')
	for app in $appnames; do
		app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')
		pure_app=$(echo "$app" | tr '-' ' ')
		sed -i "s/^| $pure_app |/| $app_lower |/g" "$arch".md
	done
done
