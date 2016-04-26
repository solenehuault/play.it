extract_icon_from() {
mkdir "${PLAYIT_WORKDIR}/icons"
local file_ext=${1##*.}
case $file_ext in
	exe) wrestool --extract --type=14 --output="${PLAYIT_WORKDIR}/icons" "$1" ;;
	ico) icotool --extract --output="${PLAYIT_WORKDIR}/icons" "$1" 2>/dev/null ;;
	bmp) convert "$1" "${PLAYIT_WORKDIR}/icons/${1%.bmp}.png" ;;
	*) liberror 'file_ext' 'extract_icon_from' ;;
esac
}

