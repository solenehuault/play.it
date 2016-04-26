set_source_archive() {
for archive in "$@"; do
	file="$(eval echo \$$archive)"
	if [ -n "$SOURCE_ARCHIVE" ] && [ "${SOURCE_ARCHIVE##*/}" = "$file" ]; then
		ARCHIVE="$archive"
		set_source_archive_vars
		return 0
	elif [ -z "$SOURCE_ARCHIVE" ] && [ -f "$file" ]; then
		SOURCE_ARCHIVE="$file"
		ARCHIVE="$archive"
		set_source_archive_vars
		return 0
	fi
done
if [ -z "$SOURCE_ARCHIVE" ]; then
	set_source_archive_error
fi
}

set_source_archive_vars() {
case ${LANG%_*} in
	fr) echo "Utilisation de ${SOURCE_ARCHIVE}" ;;
	en|*) echo "Using ${SOURCE_ARCHIVE}" ;;
esac
ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
ARCHIVE_TYPE="$(eval echo \$${archive}_TYPE)"
ARCHIVE_UNCOMPRESSED_SIZE="$(eval echo \$${archive}_UNCOMPRESSED_SIZE)"
}

set_source_archive_error () {
case ${LANG%_*} in
	fr) echo "$string_error_fr\nTODO set_source_archive_error (fr)" ;;
	en|*) echo "$string_error_en\nTODO set_source_archive_error (en)" ;;
esac
return 1
}

