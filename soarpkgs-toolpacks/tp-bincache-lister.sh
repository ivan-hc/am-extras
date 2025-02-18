#!/bin/sh

architectures="x86_64 aarch64"
for arch in $architectures; do
	curl -Ls "https://raw.githubusercontent.com/pkgforge/metadata/main/bincache/data/$arch-Linux.json" \
		| grep "{\|\"pkg_name\"\|\"description\"\|\"pkg_webpage\"\|\"download_url\"\|\"version\"" \
		| sed 's/,$/ | /g' | xargs | tr '{}' '\n' | sed 's/ pkg_name:/|/g' | sort -u \
		| sed 's/description:/ | /g; s/pkg_webpage:/ | /g; s/download_url:/ | /g; s/version:/ | /g; s/  / /g; s/  / /g' \
		| sed 's/| |/|/g' | awk -F'|' '{print $1 $2 $4 $3 $6 $5}' | sed 's/  / | /g; s/^/|/g; s/$/|/g' \
		| grep -v "| |\|||"> "$arch".md
done