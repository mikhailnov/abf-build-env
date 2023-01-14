#!/bin/bash
# $1: CSV масс-билда №1
# $2: CSV масс-билда №2

set -e
set -f
set -u
set -o pipefail

csv1="$1"
test -f "$csv1"
csv2="$2"
test -f "$csv2"
tmp="$(mktemp -d)"
trap 'rm -fr "$tmp"' EXIT
export TMPDIR="$tmp"

# failed in mass build 1
failed1="$(mktemp)"
# failed in mass build 2
failed2="$(mktemp)"
# failed only in mass build 2
failed3="$(mktemp)"

# IFS=';;' does not work properly, works as IFS=';'
grep ';;build_error;;' "$csv1" | sed -e 's,;;,;,g' -e 's,;import/,;,g' -e 's,\],},g' -e 's,\[,{,g' > "$failed1"
grep ';;build_error;;' "$csv2" | sed -e 's,;;,;,g' -e 's,;import/,;,g' -e 's,\],},g' -e 's,\[,{,g' > "$failed2"

while IFS=';' read -r -a line
do
	pkgname="${line[2]}"
	failreason="${line[4]}"
	if ! grep -q ";${pkgname};" "$failed1" #&& ! grep ";${pkgname};" "$failed1" | grep -q "${failreason}"
	then
		o=""
		for (( i=0; i<${#line[@]}; i++ ))
		do
			o="${o};;${line[$i]}"
		done
		echo "$o" >> "$failed3"
	fi
done < "$failed2"

sed -e 's,^;;,,' -e 's,{,\[,g' -e 's,},\],g' "$failed3"
