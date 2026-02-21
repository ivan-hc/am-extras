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
		}' | grep -v "nixappimage\|runimage\|appbundle\|flatimage" | \
		grep -v " teamviewer \| telegram-desktop "
	done )
	{
	printf '%s\n' "$header"
	printf '%s\n' "$rows" | sort -u
	} > "${arch}.md"
	sed -i 's# ghcr.io/# https://ghcr.io/#g' "${arch}.md"
done

# Remove apps already available in AM
TAKES_COUNT=0
am_apps=$(curl -Ls https://raw.githubusercontent.com/ivan-hc/AM/refs/heads/main/programs/x86_64-apps)
while [ "$TAKES_COUNT" -lt 10 ]; do
	if ! echo "$am_apps" | grep -q "^◆ [a-z].* : "; then
		printf "\n Apps list is empty, attempt %b of 10 will start in 5 seconds...\n\n" "$((TAKES_COUNT + 1))"
		sleep 5
	fi
	TAKES_COUNT=$((TAKES_COUNT + 1))
done

if ! echo "$am_apps" | grep -q "^◆ [a-z].* : "; then
	printf "\n Error while trying to list apps from the AM database. Exiting.\n\n"
	exit 1
fi

am_apps=$(echo "$am_apps" | awk '{print $2}')
for arch in $architectures; do
	for a in $am_apps; do
		if grep -q "^| $a |" "${arch}.md"; then
			sed -i "/^| $a |/d" "${arch}.md"
		fi
	done
done
