#!/bin/sh

arch="x86_64"
appnames=$(awk '{print $2}' ./*/x86_64.md | uniq | grep -v -- "^-\|appname$" | xargs)
for app in $appnames; do
	appname="$app"
	if ! grep -q "^| $app | [A-Z].* |$" ./descriptions.md; then
		# Determine Arch Linux web page
		if curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"/ | grep -q "Description:"; then
			manpage=$(curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"/)
		elif curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"-desktop/ | grep -q "Description:"; then
			manpage=$(curl -Ls https://archlinux.org/packages/extra/"$arch"/"$app"-desktop/)
		elif curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"/ | grep -q "Description:"; then
			manpage=$(curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"/)
		elif curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"-desktop/ | grep -q "Description:"; then
			manpage=$(curl -Ls https://archlinux.org/packages/core/"$arch"/"$app"-desktop/)
		elif curl -Ls https://aur.archlinux.org/packages/"$app" | grep -q "Description:"; then
			manpage=$(curl -Ls https://aur.archlinux.org/packages/"$app")
		elif curl -Ls https://aur.archlinux.org/packages/"$app"-git | grep -q "Description:"; then
			manpage=$(curl -Ls https://aur.archlinux.org/packages/"$app"-git)
		elif curl -Ls https://man.archlinux.org/man/"$app" | grep -q "DESCRIPTION"; then
			manpage=$(curl -Ls https://man.archlinux.org/man/"$app")
		elif curl -Ls https://manpages.debian.org/testing/"$app" | grep -q "DESCRIPTION"; then
			manpage=$(curl -Ls https://manpages.debian.org/testing/"$app")
		fi
		if echo "$manpage" | grep -q "DESCRIPTION"; then
			description=$(echo "$manpage" | grep -A 2 NAME 2>/dev/null | grep "^<p " | head -1 | sed 's#</p>$##g' | sed -- "s/&amp\;/and/g; s/&#39\;/\'/g; s/&#x00B4\;/\'/g; s/&lt\;//g; s/&#x27\;//g; s/&gt\;//g; s/ - //g" | tr '>' '\n' | tail -1 | cut -d" "  -f3-)
			[ -n "$description" ] && description=$(echo "$description" | sed 's/.*/\u&/')
			site=$(echo "$manpage" | grep -A 2 Upstream 2>/dev/null | tr '">< ' '\n' | grep -i "^http\|^ftp" | head -1)
			[ -z "$site" ] && site=$(echo "$manpage" | grep -A 200 "DESCRIPTION" | tr '"><=' '\n' | grep "^http.*" | head -1)
		else
			description=$(echo "$manpage" | grep -A 2 Description: | tr '><' '\n' | grep "^[A-Z]" | sed -- "s/&amp\;/and/g; s/&#39\;/\'/g; s/&#x00B4\;/\'/g; s/&lt\;//g; s/&#x27\;//g; s/&gt\;//g; s/ - //g" | tail -1)
			site=$(echo "$manpage" | grep -A 2 "Upstream URL" | tr '><' '\n' | grep "^http.*" | tail -1)
			if [ -z "$site" ]; then
				if curl -Ls https://manpages.debian.org/testing/"$app" | grep -q "DESCRIPTION"; then
					manpage=$(curl -Ls https://manpages.debian.org/testing/"$app")
					site=$(echo "$manpage" | grep -A 200 "DESCRIPTION" | tr '"><=' '\n' | grep "^http.*" | head -1)
				fi
			fi
		fi
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="None"
		echo "| $appname | $description | $site |" >> descriptions.md
	fi
	unset appname description site download	version manpage
done
list=$(sort -u descriptions.md | grep -v -- "|  |$\| ------- \| appname | description | site |")
echo "| appname | description | site |" > descriptions.md
echo "| ------- | ----------- | ---- |" >> descriptions.md
echo "$list" >> descriptions.md
