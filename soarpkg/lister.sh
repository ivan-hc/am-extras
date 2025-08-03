#!/bin/sh

architectures="x86_64 aarch64"
category="bincache pkgcache"

header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

for arch in $architectures; do
	rows=$( for c in $category; do
	curl -fsSL "https://raw.githubusercontent.com/pkgforge/metadata/main/$c/data/${arch}-Linux.json" | jq '.' | \
	awk '
		/"pkg_name"/    { name = $0; gsub(/.*: *"/,"",name); gsub(/".*/,"",name) }
		/"description"/ { desc = $0; gsub(/.*: *"/,"",desc); gsub(/".*/,"",desc) }
		/"pkg_webpage"/ { site = $0; gsub(/.*: *"/,"",site); gsub(/".*/,"",site) }
		/"ghcr_blob"/   { dl  = $0; gsub(/.*: *"/,"",dl); gsub(/".*/,"",dl) }
		/"version"/     { ver = $0; gsub(/.*: *"/,"",ver); gsub(/".*/,"",ver);
		printf("| %s | %s | %s | %s | %s |\n", name, desc, site, dl, ver)
		}' | grep -v "/appimage/\|nixappimage\|runimage\|appbundle\|flatimage" | \
		grep -v " teamviewer \| telegram-desktop "
	done )
	{
	printf '%s\n' "$header"
	printf '%s\n' "$rows" | sort -u
	} > "${arch}.md"
	sed -i 's# ghcr.io/# https://ghcr.io/#g' "${arch}.md"
done
