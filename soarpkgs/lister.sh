#!/bin/sh

ARCH="x86_64 aarch64"
CATEGORIES="bincache pkgcache"

#A temp_dir to avoid accidental file overwirtes or same name problems,.. terminates at failed creation
#will be removed at completion 

TMPDIR=$(mktemp -d) || exit 1

# Main Function
process_json() {
    arch="$1"
    rows_file="$TMPDIR/rows_${arch}.tsv"
    header_file="$TMPDIR/header_${arch}.md"

    # Default header
    cat > "$header_file" <<EOF
| appname | description | site | download | version |
| ------- | ----------- | ---- | -------- | ------- |
EOF

    # Clear rows_file
    > "$rows_file"

    # Fetch and parse JSON data from all categories
    for c in $CATEGORIES; do
    # Multiple urls listed on soarpkgs site...switchable
        url="https://raw.githubusercontent.com/pkgforge/metadata/main/$c/data/${arch}-Linux.json"

        curl -fsSL "$url" | \
        awk '
            /"pkg_name"/  { name = $0; gsub(/.*: *"/,"",name); gsub(/".*/,"",name) }
            /"pkg_id"/    { id = $0; gsub(/.*: *"/,"",id); gsub(/".*/,"",id) }
            /"description"/ { desc = $0; gsub(/.*: *"/,"",desc); gsub(/".*/,"",desc) }
            /"pkg_webpage"/ { site = $0; gsub(/.*: *"/,"",site); gsub(/".*/,"",site) }
            /"download_url"/{ dl  = $0; gsub(/.*: *"/,"",dl); gsub(/".*/,"",dl) }
            /"version"/     {
                ver = $0; gsub(/.*: *"/,"",ver); gsub(/".*/,"",ver);
                # Output tab separated fields:
                # appname, pkg_id, description, site, download_url, version
                print name "\t" id "\t" desc "\t" site "\t" dl "\t" ver
            }
        ' >> "$rows_file"
    done

    # Pick duplicate appnames
    awk -F '\t' '
    {
        appname = $1;
        pkgid = $2;
        desc = $3;
        site = $4;
        dl = $5;
        ver = $6;

        lines[NR] = $0;
        appnames[NR] = appname;
        pkgids[NR] = pkgid;

        count[appname]++;
        group_lines[appname] = group_lines[appname] ? group_lines[appname] SUBSEP NR : NR;
    }
    END {
        #1: For each duplicate appname find unique word in pkg_id
        for (name in count) {
            if (count[name] == 1) {
                single[name] = 1; 
            } else {
                split(group_lines[name], arr, SUBSEP);
                delete wordcount;

                # Counting repetitions
                for (i in arr) {
                    line_i = arr[i];
                    id = pkgids[line_i];
                    nwords = split(id, wlist, /[^a-zA-Z0-9]+/);
                    for (j=1; j<=nwords; j++) {
                        w = wlist[j];
                        if (w != "")
                            wordcount[w]++;
                    }
                }

                # By line,first unique word from pkg_id
                for (i in arr) {
                    line_i = arr[i];
                    id = pkgids[line_i];
                    nwords = split(id, wlist, /[^a-zA-Z0-9]+/);
                    unique_word[line_i] = "";
                    for (j=1; j<=nwords; j++) {
                        w = wlist[j];
                        if (w != "" && wordcount[w] == 1) {
                            unique_word[line_i] = w;
                            break;
                        }
                    }
                }
            }
        }

        # 2: apply minimal unique suffix by dot segments for further uniqueness - collect appname
        for (name in count) {
            if (count[name] > 1) {
                split(group_lines[name], arr, SUBSEP);
                ambiguous_lines = "";
                for (i in arr) {
                    line_i = arr[i];
                    if (unique_word[line_i] == "") {
                        ambiguous_lines = ambiguous_lines ? ambiguous_lines SUBSEP line_i : line_i;
                    }
                }
                if (ambiguous_lines != "") {
                    split(ambiguous_lines, amb_arr, SUBSEP);

                    # Gather pkg_id parts
                    max_segs = 0;
                    for (i in amb_arr) {
                        idx = amb_arr[i];
                        n = split(pkgids[idx], tmp_parts, ".");
                        if (n > max_segs) max_segs = n;
                        seg_count[idx] = n;
                        for (s = 1; s <= n; s++) {
                            parts[idx, s] = tmp_parts[s];
                        }
                    }

                    # finding minimal unique suffix
                    for (len=1; len<=max_segs; len++) {
                        delete seen_suffix;
                        conflict=0;
                        for (i in amb_arr) {
                            idx = amb_arr[i];
                            n = seg_count[idx];
                            start = n - len + 1;
                            if (start < 1) start = 1;
                            suffix = parts[idx,start];
                            for (k = start + 1; k <= n; k++) {
                                suffix = suffix "-" parts[idx, k];
                            }
                            suffixes[idx] = suffix;

                            if (seen_suffix[suffix]++) {
                                conflict=1;
                                break;
                            }
                        }
                        if (!conflict) {
                            # If minimal unique suffix
                            for (i in amb_arr) {
                                idx = amb_arr[i];
                                unique_word[idx] = suffixes[idx];
                            }
                            break;
                        }
                    }

                    # If conflict fallback "id"
                    for (i in amb_arr) {
                        idx = amb_arr[i];
                        if (unique_word[idx] == "") {
                            unique_word[idx] = "id";
                        }
                    }
                }
            }
        }

        # The -nix suffix
        for (i=1; i<=NR; i++) {
            split(lines[i], f, "\t");
            appn = f[1];
            pkgid = f[2];
            desc = f[3];
            site = f[4];
            dl = f[5];
            ver = f[6];

            if (single[appn] == 1) {
                name_out = appn;
                suffix = "";
            } else {
                suffix = unique_word[i];

                # Repetition fix with "default"
                if (suffix == appn) {
                    suffix = "default";
                }

                name_out = appn "-" suffix;
            }

            # nix suffix only if pkg_id has "nixpkgs" and suffix  x= "nixpkgs"
            if (tolower(pkgid) ~ /nixpkgs/ && tolower(suffix) !~ /nixpkgs/) {
                name_out = name_out "-nix";
            }

            print "| " name_out " | " desc " | " site " | " dl " | " ver " |";
        }
    }
    ' "$rows_file" | sort -u > "${arch}.md"

    # Generate markdown file
    cat "$header_file" "${arch}.md" > "$TMPDIR/final_${arch}.md"
    mv "$TMPDIR/final_${arch}.md" "${arch}.md"
}

# ARchitecture loop
for arch in $ARCH; do
    process_json "$arch"
done

# Clean
rm -rf "$TMPDIR"
