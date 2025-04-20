#!/bin/sh

architectures="x86_64"
for arch in $architectures; do
	rm -f "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	curl -Ls "$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*metadata_$arch-Linux.json$" | head -1)" \
		| grep "{\|\"pkg_name\"\|\"description\"\|\"homepage\"\|\"download_url\"\|\"version\"" \
		| sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg_name:/|/g' | sort -u \
		| sed 's/description:/ | /g; s/homepage:/ | /g; s/download_url:/ | /g; s/version:/ | /g; s/  / /g; s/  / /g; s/ (may be inaccurate)//g' \
		| sed 's/| |/|/g' | awk -F'|' '{print $1 $2 $3 $6 $5 $4}' | sed 's/  / | /g; s/^/|/g; s/$/|/g' \
		| grep -v "| |\|||\||[a-zA-Z0-9]" \
		| grep -i "^| .* | .* | http.* | http.*download.* | .* |$" | sort -u >> "$arch".md
	appnames=$(awk -F'|' '{print $2}' "$arch".md | grep -v -- "appname\|---" | tr ' ' '-' | sed -- 's/^-//g; s/-$//g')
	for app in $appnames; do
		app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')
		pure_app=$(echo "$app" | tr '-' ' ')
		sed -i "s/^| $pure_app |/| $app_lower |/g" "$arch".md
	done
	list=$(sort "$arch".md)
	printf "| appname | description | site | download | version |\n%b" "$list" > "$arch".md
done
