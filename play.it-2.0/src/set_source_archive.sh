# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: set_source_archive_vars, set_source_archive_error
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
		set_source_archive_error_not_found
	fi
}

# set archive-related vars
# USAGE: set_source_archive_vars
# NEEDED_VARS: ARCHIVE, $ARCHIVE_MD5, $ARCHIVE_TYPE, $ARCHIVE_UNCOMPRESSED_SIZE
# CALLS: set_source_archive_print, set_source_archive_error_no_type
# CALLED BY: set_source_archive
set_source_archive_vars() {
	set_source_archive_print
	ARCHIVE_TYPE="$(eval echo \$${archive}_TYPE)"
	if [ -z "$ARCHIVE_TYPE" ]; then
		if [ -n "$(echo "${SOURCE_ARCHIVE##*/}" | grep '^gog_.*\.sh$')" ]; then
			ARCHIVE_TYPE='mojosetup'
		elif [ -n "$(echo "${SOURCE_ARCHIVE##*/}" | grep '^setup_.*\.exe$')" ]; then
			ARCHIVE_TYPE='innosetup'
		else
			set_source_archive_error_no_type
		fi
		eval ${archive}_TYPE=$ARCHIVE_TYPE
	fi
	ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
	ARCHIVE_UNCOMPRESSED_SIZE="$(eval echo \$${archive}_UNCOMPRESSED_SIZE)"
}

# print archive use message
# USAGE: set_source_archive_print
# CALLED BY: set_source_archive_vars
set_source_archive_print() {
	case ${LANG%_*} in
		('fr')
			echo "Utilisation de $SOURCE_ARCHIVE"
		;;
		('en'|*)
			echo "Using $SOURCE_ARCHIVE"
		;;
	esac
}

# display an error message telling the target archive has not been found
# USAGE: set_source_archive_error_not_found
# CALLED BY: set_source_archive
set_source_archive_error_not_found() {
	case ${LANG%_*} in
		('fr')
			echo "$string_error_fr"
			echo "La cible de ce script est introuvable"
		;;
		('en'|*)
			echo "$string_error_en"
			echo "The script target could not be found"
		;;
	esac
	return 1
}

# display an error message telling the type of the target archive is not set
# USAGE: set_source_archive_error_no_type
# CALLED BY: set_source_archive_vars
set_source_archive_error_no_type() {
	case ${LANG%_*} in
		('fr')
			echo "$string_error_fr"
			echo "ARCHIVE_TYPE n’est pas défini pour $SOURCE_ARCHIVE"
		;;
		('en'|*)
			echo "$string_error_en"
			echo "ARCHIVE_TYPE is not set for $SOURCE_ARCHIVE"
		;;
	esac
	return 1
}

