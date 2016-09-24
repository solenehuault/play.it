# extract data from given archive
# USAGE: extract_data $archive
# NEEDED_VARS: PLAYIT_WORKDIR, ARCHIVE, $ARCHIVE_TYPE, ARCHIVE_PASSWD
# CALLS: liberror, extract_7z (declared by check_deps_7z)
extract_data_from() {
case ${LANG%_*} in
	fr) echo "Extraction des données de ${1##*/}" ;;
	en|*) echo "Extracting data from ${1##*/}" ;;
esac
local destination="${PLAYIT_WORKDIR}/gamedata"
mkdir --parents "$destination"
archive_type=$(eval echo \$${ARCHIVE}_TYPE)
case $archive_type in
	7z) extract_7z "$1" "$destination" ;;
	innosetup) innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$1" ;;
	mojosetup) unzip -d "$destination" "$1" 1>/dev/null 2>/dev/null || true ;;
	nix_stage1)
		local input_blocksize=$(head --lines=514 "$1" | wc --bytes | tr --delete ' ')
		dd if="$1" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar xf - --directory "$destination"
	;;
	nix_stage2)
		mv "$1" "$destination/${1##*/}.tar.xz"
		mkdir "$destination/${1##*/}"
		tar xf "$destination/${1##*/}.tar.xz" -C "$destination/$1"
	;;
	tar) tar xf "$1" -C "$destination" ;;
	rar) UNAR_OPTIONS="-output-directory \"$destination\" -no-directory"
		[ -n "$ARCHIVE_PASSWD" ] && UNAR_OPTIONS="$UNAR_OPTIONS -password \"$ARCHIVE_PASSWD\""
		unar $UNAR_OPTIONS "$1"	;;
	zip) unzip -d "$destination" "$1" 1>/dev/null ;;
	*) liberror 'ARCHIVE_TYPE' 'extract_data_from' ;;
esac
}

