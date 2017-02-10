# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
set_archive() {
	local name=$1
	shift 1
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			export $name="$archive"
			return 0
		elif [ -f "${SOURCE_ARCHIVE%/*}/$archive" ]; then
			export $name="${SOURCE_ARCHIVE%/*}/$archive"
			return 0
		fi
	done
	unset $name
}

# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: set_source_archive_vars set_source_archive_error
# 	set_source_archive_print
set_source_archive() {
	for archive in "$@"; do
		file="$(eval echo \$$archive)"
		if [ -n "$SOURCE_ARCHIVE" ] && [ "${SOURCE_ARCHIVE##*/}" = "$file" ]; then
			ARCHIVE="$archive"
			set_source_archive_print
			set_source_archive_vars
			return 0
		elif [ -z "$SOURCE_ARCHIVE" ] && [ -f "$file" ]; then
			SOURCE_ARCHIVE="$file"
			ARCHIVE="$archive"
			set_source_archive_print
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
# NEEDED_VARS: ARCHIVE ARCHIVE_MD5 ARCHIVE_TYPE ARCHIVE_UNCOMPRESSED_SIZE
# CALLS: set_source_archive_error_no_type
# CALLED BY: set_source_archive file_checksum
set_source_archive_vars() {
	ARCHIVE_TYPE="$(eval echo \$${archive}_TYPE)"
	if [ -z "$ARCHIVE_TYPE" ]; then
		case "${SOURCE_ARCHIVE##*/}" in
			(gog_*.sh)
				ARCHIVE_TYPE='mojosetup'
			;;
			(setup_*.exe|patch_*.exe)
				ARCHIVE_TYPE='innosetup'
			;;
			(*.zip)
				ARCHIVE_TYPE='zip'
			;;
			(*.tar.gz)
				ARCHIVE_TYPE='tar.gz'
			;;
			(*)
				set_source_archive_error_no_type
			;;
		esac
		eval ${archive}_TYPE=$ARCHIVE_TYPE
	fi
	ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
	ARCHIVE_UNCOMPRESSED_SIZE="$(eval echo \$${archive}_UNCOMPRESSED_SIZE)"
	PKG_VERSION="$(eval echo \$${archive}_VERSION)"
}

# print archive use message
# USAGE: set_source_archive_print
# CALLED BY: set_source_archive
set_source_archive_print() {
	case ${LANG%_*} in
		('fr')
			printf 'Utilisation de %s\n' "$SOURCE_ARCHIVE"
		;;
		('en'|*)
			printf 'Using %s\n' "$SOURCE_ARCHIVE"
		;;
	esac
}

# display an error message telling the target archive has not been found
# USAGE: set_source_archive_error_not_found
# CALLED BY: set_source_archive
set_source_archive_error_not_found() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'La cible de ce script est introuvable\n'
		;;
		('en'|*)
			printf 'The script target could not be found\n'
		;;
	esac
	return 1
}

# display an error message telling the type of the target archive is not set
# USAGE: set_source_archive_error_no_type
# CALLED BY: set_source_archive_vars
set_source_archive_error_no_type() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'ARCHIVE_TYPE n’est pas défini pour %s\n' "$SOURCE_ARCHIVE"
		;;
		('en'|*)
			printf 'ARCHIVE_TYPE is not set for %s\n' "$SOURCE_ARCHIVE"
		;;
	esac
	return 1
}

