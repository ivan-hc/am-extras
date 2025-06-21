#!/bin/sh

architectures="i686 x86_64"
custom="false"
ref="https://busybox.net"; VERSION=$(curl -Ls https://raw.githubusercontent.com/ivan-hc/busybox-tools/refs/heads/main/version)

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
		fi
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="$ref"
		[ -z "$version" ] && version="$VERSION" #version=$(echo "$download" | tr '/' '\n' | tail -2 | head -1)
		echo "| $appname | $description | $site | $download | $version |" >> "$arch".md
		unset appname description site download	version archpage
	done
	list=$(sort -u "$arch".md | grep -i "^| .* | .* | http.* | http.* | .* |$")
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	echo "$list" >> "$arch".md
done
