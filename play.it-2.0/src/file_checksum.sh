
# check integrity of target file
# USAGE: file_checksum $file $archive_name[…]
# NEEDED VARS: CHECKSUM_METHOD
# CALLS: file_checksum_md5, file_checksum_none, liberror
file_checksum() {
local source_file="$1"
shift 1
case $CHECKSUM_METHOD in
	md5) file_checksum_md5 $@ ;;
	none) file_checksum_none ;;
	*) liberror 'CHECKSUM_METHOD' 'file_checksum' ;;
esac
}

# check integrity of target file against MD5 control sum
# USAGE: file_checksum_md5 $archive_name[…]
# NEEDED VARS: $archive_MD5
# CALLS: set_source_archive_vars
# CALLED BY: file_checksum
file_checksum_md5() {
case ${LANG%_*} in
	fr) echo "Contrôle de l’intégrité de ${source_file##*/}" ;;
	en|*) echo "Checking ${source_file##*/} integrity" ;;
esac
FILE_MD5="$(md5sum "$source_file" | cut --delimiter=' ' --fields=1)"
for archive in $@; do
	local archive_md5=$(eval echo \$${archive}_MD5)
	if [ "$FILE_MD5" = "$archive_md5" ]; then
		if [ -z "$ARCHIVE" ]; then
			ARCHIVE="$archive"
			set_source_archive_vars
		fi
		return 0
	fi
done
case ${LANG%_*} in
	fr) echo "$string_error_fr\nSomme de contrôle incohérente. $source_file n’est pas le fichier attendu.\nUtilisez --checksum=none pour forcer son utilisation." ;;
	en|*) echo "$string_error_en\nHasum mismatch. $source_file is not the expected file.\nUse --checksum=none to force its use." ;;
esac
return 1
}

# set source archive if not already set by script arguments
# USAGE: file_checksum_none
# NEEDED_VARS: ARCHIVE, ARCHIVE_DEFAULT
# CALLS: set_source_archive_vars
# CALLED BY: file_checksum
file_checksum_none() {
if [ -z "$ARCHIVE" ]; then
	ARCHIVE="$ARCHIVE_DEFAULT"
	set_source_archive_vars
fi
}
