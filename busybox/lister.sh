#!/bin/sh
ARCH="x86_64 i686"
site="https://busybox.net"
version=$(curl -Ls https://raw.githubusercontent.com/ivan-hc/busybox-tools/refs/heads/main/version)
descriptions=$(curl -fsSL "https://raw.githubusercontent.com/pkgforge/metadata/main/bincache/data/x86_64-Linux.json" | jq '.' | \
	awk '
		/"pkg_name"/    { name = $0; gsub(/.*: *"/,"",name); gsub(/".*/,"",name) }
		/"description"/ { desc = $0; gsub(/.*: *"/,"",desc); gsub(/".*/,"",desc);
		printf("| %s | %s |\n", name, desc)
		}')
header='| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |'

_sources() {
	source_list=$(curl -Ls "https://github.com/ivan-hc/busybox-tools/tree/main/$arch-binaries")
	pkg_and_dl=$(echo "$source_list " | tr '">< ' '\n' | grep "^busybox_[A-Z]" | sed 's#^#https://raw.githubusercontent.com/ivan-hc/busybox-tools/refs/heads/main/x86_64-binaries/#g')
	appnames=$(echo "$pkg_and_dl" | sed 's:.*/::; s/^busybox_//g; s/-/\n/g' | grep "^[A-Z]" | tr '[:upper:]' '[:lower:]')
}

for arch in $ARCH; do
	printf '%s\n' "$header" > "$arch".md
	_sources
	for app in $appnames; do
		appname=$( echo "$app" | tr '_' '-')
		download=$(echo "$pkg_and_dl" | tr ' ' '\n' | grep -i "^https.*/busybox_$app$")
		description=$(echo "$descriptions" | grep "^| $appname |" | awk -F'|' '{print $3}' | sed 's/^ //g; s/ $//g; s/  / /g' | grep -i busybox | head -1 | sed 's/ \[.*\]/\./g')
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description download
	done
done
