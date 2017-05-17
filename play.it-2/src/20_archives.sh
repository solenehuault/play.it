# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: check_deps file_checksum set_archive_print
set_archive() {
	local name=$1
	shift 1
	unset $name
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			export $name="$archive"
			set_archive_print "$archive"
		elif [ -f "${SOURCE_ARCHIVE%/*}/$archive" ]; then
			export $name="${SOURCE_ARCHIVE%/*}/$archive"
			set_archive_print "${SOURCE_ARCHIVE%/*}/$archive"
		fi
	done
	if [ -n "$(eval echo \$$name)" ]; then
		check_deps
		file_checksum "$(eval echo \$$name)"
	fi
}

# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: set_source_archive_vars set_source_archive_error set_archive_print
set_source_archive() {
	for archive in "$@"; do
		file="$(eval echo \$$archive)"
		if [ -n "$SOURCE_ARCHIVE" ] && [ "${SOURCE_ARCHIVE##*/}" = "$file" ]; then
			ARCHIVE="$archive"
			set_archive_print "$SOURCE_ARCHIVE"
			set_source_archive_vars
		elif [ -z "$SOURCE_ARCHIVE" ] && [ -f "$file" ]; then
			SOURCE_ARCHIVE="$file"
			ARCHIVE="$archive"
			set_archive_print "$SOURCE_ARCHIVE"
			set_source_archive_vars
		fi
	done
	if [ -z "$SOURCE_ARCHIVE" ]; then
		set_source_archive_error_not_found "$@"
	fi
	check_deps
	file_checksum "$SOURCE_ARCHIVE"
}

# set archive-related vars
# USAGE: set_source_archive_vars
# NEEDED_VARS: ARCHIVE ARCHIVE_MD5 ARCHIVE_TYPE ARCHIVE_SIZE
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
			(*.tar.gz|*.tgz)
				ARCHIVE_TYPE='tar.gz'
			;;
			(*)
				set_source_archive_error_no_type
			;;
		esac
		eval ${archive}_TYPE=$ARCHIVE_TYPE
	fi
	ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
	ARCHIVE_SIZE="$(eval echo \$${archive}_SIZE)"
	PKG_VERSION="$(eval echo \$${archive}_VERSION)+${script_version}"
}

# print archive use message
# USAGE: set_archive_print $file
# CALLED BY: set_archive set_source_archive
set_archive_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Utilisation de %s\n'
		;;
		('en'|*)
			string='Using %s\n'
		;;
	esac
	printf "$string" "$1"
}

# display an error message telling the target archive has not been found
# USAGE: set_source_archive_error_not_found
# CALLED BY: set_source_archive
set_source_archive_error_not_found() {
	print_error
	local string
	if [ "$#" = 1 ]; then
		case ${LANG%_*} in
			('fr')
				string='Le fichier suivant est introuvable :\n'
			;;
			('en'|*)
				string='The following file could not be found:'
			;;
		esac
	else
		case ${LANG%_*} in
			('fr')
				string='Aucun des fichiers suivant n’est présent :\n'
			;;
			('en'|*)
				string='None of the following files could be found:\n'
			;;
		esac
	fi
	printf "$string"
	for archive in "$@"; do
		printf '%s\n' "$(eval echo \$$archive)"
	done
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

# check integrity of target file
# USAGE: file_checksum $file
# NEEDED VARS: CHECKSUM_METHOD
# CALLS: file_checksum_md5, file_checksum_none, liberror
file_checksum() {
	case $CHECKSUM_METHOD in
		('md5')
			file_checksum_md5 "$1"
		;;
		('none')
			return 0
		;;
		(*)
			liberror 'CHECKSUM_METHOD' 'file_checksum'
		;;
	esac
}

# check integrity of target file against MD5 control sum
# USAGE: file_checksum_md5 $file
# NEEDED VARS: ARCHIVE ARCHIVE_MD5
# CALLS: file_checksum_print, file_checksum_error
# CALLED BY: file_checksum
file_checksum_md5() {
	file_checksum_print "$(basename "$1")"
	FILE_MD5="$(md5sum "$1" | cut --delimiter=' ' --fields=1)"
	if [ "$FILE_MD5" = "$(eval echo \$${ARCHIVE}_MD5)" ]; then
		return 0
	fi
	file_checksum_error "$1"
	return 1
}

# print integrity check message
# USAGE: file_checksum_print $file_name
# CALLED BY: file_checksum_md5
file_checksum_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Contrôle de l’intégrité de %s\n'
		;;
		('en'|*)
			string='Checking integrity of %s\n'
		;;
	esac
	printf "$string" "$1"
}

# print integrity check error message
# USAGE: file_checksum_error $file
# CALLED BY: file_checksum_md5
file_checksum_error() {
	print_error
	local string1
	local string2
	case ${LANG%_*} in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.\n'
			string2='Utilisez --checksum=none pour forcer son utilisation.\n'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.\n'
			string2='Use --checksum=none to force its use.\n'
		;;
	esac
	printf "$string1" "$1"
	printf "$string2"
}

