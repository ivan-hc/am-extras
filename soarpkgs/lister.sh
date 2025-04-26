#!/bin/sh

architectures="x86_64 aarch64"
categories="bincache pkgcache"
for arch in $architectures; do
	rm -f "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	for c in $categories; do
		curl -Ls "https://github.com/pkgforge/$c/releases/download/metadata/$arch-Linux.json" | jq '.' \
		| grep "{\|\"pkg_name\"\|\"description\"\|\"pkg_webpage\"\|\"download_url\"\|\"version\"" \
		| sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg_name:/|/g' | sort -u \
		| sed 's/description:/ | /g; s/pkg_webpage:/ | /g; s/download_url:/ | /g; s/version:/ | /g; s/  / /g; s/  / /g' \
		| sed 's/| |/|/g' | awk -F'|' '{print $1 $2 $4 $3 $6 $5}' | sed 's/  / | /g; s/^/|/g; s/$/|/g' \
		| grep -v "| |\|||\||[a-zA-Z0-9]" | grep -vi "/nixappimage/" | grep -vi "0ad-matters\|ivan-hc" \
		| grep -i "^| .* | .* | http.* | http.*download.* | .* |$" | sort -u >> "$arch".md
	done
	list=$(sort -u "$arch".md)
	printf "| appname | description | site | download | version |\n%b" "$list" > "$arch".md
done
