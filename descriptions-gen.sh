#!/bin/sh

arch="x86_64"

_check_manpage() {
	# Determine man page
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
}

_convert_html_specia_entries() {
	perl -n -mHTML::Entities -e ' ; print HTML::Entities::decode_entities($_) ;'
}

_debian_fallback() {
	if [ -z "$description" ] && echo "$manpage" | grep -q "archlinux"; then
		if curl -Ls https://manpages.debian.org/testing/"$app" | grep -q "DESCRIPTION"; then
			manpage=$(curl -Ls https://manpages.debian.org/testing/"$app")
			description=$(echo "$manpage" | grep -A 2 NAME 2>/dev/null | grep "^<p " | head -1 | sed 's#</p>$##g' | _convert_html_specia_entries | sed 's/ - //g' | tr '>' '\n' | tail -1 | cut -d" "  -f3-  | sed 's/.*/\u&/')
		fi
	fi
	if [ -z "$site" ] && echo "$manpage_bkp" | grep -q "archlinux" && echo "$manpage" | grep -q "debian"; then
		site=$(echo "$manpage_bkp" | grep -A 200 "DESCRIPTION" | tr '"><=' '\n' | grep "^http.*" | _convert_html_specia_entries | head -1)
		echo "$site" | grep -q "snapshot.debian.org" && site=""
	fi
}

_man7_org_fallback() {
	if [ -z "$description" ]; then
		if curl -Ls https://man7.org/linux/man-pages/dir_all_alphabetic.html | grep -q ">$app("; then
			manpage=$(curl -Ls https://man7.org/linux/man-pages/dir_all_alphabetic.html | grep ">$app(" | head -1 | tr '"' '\n' | grep "html$" | sed 's#^.#https://man7.org/linux/man-pages#g')
			description=$(echo "$manpage_bkp" | grep -A 2 NAME 2>/dev/null | grep "^<p " | head -1 | sed 's#</p>$##g' | _convert_html_specia_entries | sed 's/ - //g' | tr '>' '\n' | tail -1 | cut -d" "  -f3-  | sed 's/.*/\u&/')
			site=$(echo "$manpage_bkp" | grep -A 2 Upstream 2>/dev/null | tr '">< ' '\n' | grep -i "^http\|^ftp" | _convert_html_specia_entries | head -1)
		fi
	fi
}

_linuxcommandlibrary_fallback() {
	if [ -z "$description" ]; then
		if curl -Ls "https://linuxcommandlibrary.com/man/$app" | grep -q 'name="description"'; then
			manpage=$(curl -Ls "https://linuxcommandlibrary.com/man/$app")
			description=$(echo "$manpage" | grep 'name="description"' | tr '"><:' '\n' | grep . | tail -1 | sed 's/^ //g')
			echo "$description" | grep -q "Handy cheat sheets with linux tips" && description=""
		fi
	fi
}

_pkgforge_sources() {
	[ -z "$description" ] && description=$(echo "$manpage" | grep '"description":' | tr '"' '\n' | tail -1 | sed 's/,$/./g')
	[ -z "$site" ] && site=$(echo "$manpage" | grep -A 2 '"homepage"' | tr '"' '\n' | grep "http.*//")
	[ -z "$site" ] && site=$(echo "$manpage" | grep -A 2 '"src_url"' | tr '"' '\n' | grep "http.*//")
}

_pkgforge_fallback() {
	if [ -z "$description" ]; then
		if curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/$app/official/$app/raw.json" | grep -q '"description":'; then
			manpage=$(curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/$app/official/$app/raw.json")
			_pkgforge_sources
			if [ -z "$description" ]; then
				if curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/busybox/official/$app/raw.json" | grep -q '"description":'; then
					manpage=$(curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/busybox/official/$app/raw.json")
					_pkgforge_sources
					if [ -z "$description" ]; then
						if curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/busybox/glibc/$app/raw.json" | grep -q '"description":'; then
							manpage=$(curl -Ls "https://pkgs.pkgforge.dev/repo/bincache/x86_64-linux/busybox/glibc/$app/raw.json")
							_pkgforge_sources
						fi
					fi
					[ -z "$site" ] && site="https://busybox.net"
				fi
			fi
		fi
	fi
}

appnames=$(awk '{print $2}' ./*/x86_64.md | uniq | grep -v -- "^-\|appname$" | xargs)
for app in $appnames; do
	appname="$app"
	if ! grep -q "^| $app | [A-Z].* |$" ./descriptions.md; then
		_check_manpage
		if [ -z "$manpage" ]; then
			app=$(echo "$app" | sed 's/_/-/g')
			_check_manpage
		fi
		manpage_bkp="$manpage"
		if echo "$manpage_bkp" | grep -q "DESCRIPTION"; then
			description=$(echo "$manpage_bkp" | grep -A 2 NAME 2>/dev/null | grep "^<p " | head -1 | sed 's#</p>$##g' | _convert_html_specia_entries | sed 's/ - //g' | tr '>' '\n' | tail -1 | cut -d" "  -f3-  | sed 's/.*/\u&/')
			site=$(echo "$manpage_bkp" | grep -A 2 Upstream 2>/dev/null | tr '">< ' '\n' | grep -i "^http\|^ftp" | _convert_html_specia_entries | head -1)
			_debian_fallback
		else
			description=$(echo "$manpage_bkp" | grep -A 2 Description: | tr '><' '\n' | grep "^[A-Z]" | _convert_html_specia_entries | tail -1)
			site=$(echo "$manpage_bkp" | grep -A 200 "Upstream URL" | tr '><' '\n' | grep "^http.*//.*" | _convert_html_specia_entries | head -1)
			echo "$description" | grep -q "Description:" &&	description=""
			_debian_fallback
		fi
		_man7_org_fallback
		_linuxcommandlibrary_fallback
		_pkgforge_fallback
		[ -z "$description" ] && description="No description available"
		[ -z "$site" ] && site="None"
		echo " Add \"$appname\" - $description"
		echo "| $appname | $description | $site |" >> descriptions.md
	fi
	unset appname description site download	version manpage
done
list=$(sort -u descriptions.md | grep -v -- "|  |$\| ------- \| appname | description | site |\|^| .*pkgforge.* | .* | .* |$")
echo "| appname | description | site |" > descriptions.md
echo "| ------- | ----------- | ---- |" >> descriptions.md
echo "$list" >> descriptions.md
