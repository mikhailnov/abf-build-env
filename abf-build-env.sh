#!/bin/bash

set -e
set -u
set -o pipefail

# Download csv from https://abf.io/platforms/rosaY/mass_builds/X
# Include "installed_pkgs.log.gz" into it
# $1: path to csv file
_csv_to_urls(){
	local csv="$1"
	cat "$csv" | awk -F ';;' '{print $6}' | sed -e 's,?show=true$,,'
}

# "ninja-1.11.1-1.x86_64 ..." -> ninja
# $1: line of installed_pkgs.log.gz
_nevra_to_name(){
	local nevra="$(echo "$1" | awk '{print $1}')"
	local num=${#nevra}
	# find position of last dot (.arch)
	for (( c=$num; c>0; c-- ))
	do
		if [ ${nevra:$c-1:1} = . ]; then
			break
		fi
	done
	c=$((c-1))
	echo "$nevra" | head -c"$c" | rev | cut -d '-' -f 3- | rev
}

_main(){
	DESTDIR="${DESTDIR:-$PWD}"
	while read -r line
	do
		local url
		url="$(echo "$line" | awk -F ';;' '{print $6}' | sed -e 's,?show=true$,,')"
		# e.g.: 4280199;;unpermitted_arch;;import/4kstogram;;aarch64;;Empty;;""
		if [ "$url" = '""' ]; then
			continue
		fi
		local name
		name="$(echo "$line" | awk -F ';;' '{print $3}' | awk -F'/' '{print $NF}')"
		wget -O "$DESTDIR"/"$name".tmp1 "$url"
		while read -r line2
		do
			_nevra_to_name "$line2" >> "$DESTDIR"/"$name".tmp2
		done < "$DESTDIR"/"$name".tmp1
		sort -u "$DESTDIR"/"$name".tmp2 > "$DESTDIR"/"$name"
		unlink "$DESTDIR"/"$name".tmp1
		unlink "$DESTDIR"/"$name".tmp2
	done < "$1"
}

if [ "${SOURCING:-0}" != 1 ]; then
	_main "$@"
fi
