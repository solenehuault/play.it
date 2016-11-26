# extract .png or .ico files from given file
# USAGE: extract_icons_from $file[…]
# NEEDED VARS: PLAYIT_WORKDIR
# CALLS: liberror
extract_icon_from() {
	for file in "$@"; do
		local destination="${PLAYIT_WORKDIR}/icons"
		mkdir --parents "$destination"
		case ${file##*.} in
			('exe')
				wrestool --extract --type=14 --output="$destination" "$file"
			;;
			('ico')
				icotool --extract --output="$destination" "$file" 2>/dev/null
			;;
			('bmp')
				local filename="${file##*/}"
				convert "$file" "$destination/${filename%.bmp}.png"
			;;
			(*)
				liberror 'file_ext' 'extract_icon_from'
			;;
		esac
	done
}

