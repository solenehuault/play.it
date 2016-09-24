
# convert files name to lower case
# USAGE: tolower $dir
tolower() {
[ -d "$1" ] || return 1
find "$1" -depth | while read file; do
	newfile="${file%/*}/$(echo "${file##*/}" | tr [:upper:] [:lower:])"
	if [ "$newfile" != "$file" ] && [ "$file" != "$1" ]; then
		mv --verbose "$file" "$newfile"
	fi
done
}

