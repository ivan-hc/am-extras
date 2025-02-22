#!/bin/sh

architectures="x86_64"
for arch in $architectures; do
	echo "| appname | description | site | download | version |" > "$arch".md
	echo "| ------- | ----------- | ---- | -------- | ------- |" >> "$arch".md
	curl -Ls "$(curl -Ls https://api.github.com/repos/xplshn/AppBundleHUB/releases/latest | sed 's/[()",{} ]/\n/g' | grep -oi "http.*download.*metadata_$arch-Linux.json$" | head -1)" \
	| jq -r '
	.appbundlehub[] | 
	.version |= (if type == "string" then sub("\\(may be inaccurate\\)"; "") else . end) |
	.pkg_name |= ascii_downcase |
	"| \(.pkg_name) | \(.description) | \(.homepage) | \(.download_url) | \(.version)|"' >> "$arch".md
done
