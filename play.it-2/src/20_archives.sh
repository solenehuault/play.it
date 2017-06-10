# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED VARS: (LANG)
# CALLS: set_archive_error_not_found
set_source_archive() {
	set_archive 'SOURCE_ARCHIVE' "$@"
	if [ "$SOURCE_ARCHIVE" ]; then
		return 0
	else
		set_archive_error_not_found "$@"
	fi
}

# display an error message if a mandatory archive is not found
# USAGE: set_archive_error_not_found $archive[…]
# NEEDED VARS: (LANG)
# CALLED BY: set_source_archive
set_archive_error_not_found() {
	print_error
	local string
	if [ "$#" = 1 ]; then
		case "${LANG%_*}" in
			('fr')
				string='Le fichier suivant est introuvable :\n'
			;;
			('en'|*)
				string='The following file could not be found:\n'
			;;
		esac
	else
		case "${LANG%_*}" in
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
		printf '%s\n' "$(eval printf -- "%b" "\$$archive")"
	done
	return 1
}

# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: (LANG) (SOURCE_ARCHIVE)
# CALLS: set_archive_vars
set_archive() {
	local name=$1
	shift 1
	if [ -n "$(eval printf -- "%b" "\$$name")" ]; then
		for archive in "$@"; do
			local file="$(eval printf -- "%b" "\$$archive")"
			if [ "$(basename "$(eval printf -- "%b" "\$$name")")" = "$file" ]; then
				set_archive_vars "$archive" "$name" "$(eval printf -- "%b" "\$$name")"
				return 0
			fi
		done
	else
		for archive in "$@"; do
			local file="$(eval printf -- "%b" "\$$archive")"
			if [ -f "$file" ]; then
				set_archive_vars "$archive" "$name" "$file"
				return 0
			elif [ "$SOURCE_ARCHIVE" ] && [ -f "${SOURCE_ARCHIVE%/*}/$file" ]; then
				file="${SOURCE_ARCHIVE%/*}/$file"
				set_archive_vars "$archive" "$name" "$file"
				return 0
			fi
		done
	fi
	unset $name
}

# set archive-specific variables
# USAGE: set_archive_vars $archive $name $file
# CALLS: archive_guess_type check_deps set_archive_print
# NEEDED_VARS: (LANG)
# CALLED BY: set_archive
set_archive_vars() {
	export ARCHIVE="$1"

	local name="$2"
	local file="$3"

	set_archive_print "$file"

	# set target file
	export $name="$file"

	# set archive type + check dependencies
	if [ -z "$(eval printf -- "%b" "\$${ARCHIVE}_TYPE")" ]; then
		archive_guess_type "$file"
	fi
	export ${name}_TYPE="$(eval printf -- "%b" "\$${ARCHIVE}_TYPE")"
	check_deps

	# compute total size of all archives
	if [ -n "$(eval printf -- "%b" "\$${ARCHIVE}_SIZE")" ]; then
		[ "$ARCHIVE_SIZE" ] || export ARCHIVE_SIZE='0'
		export ARCHIVE_SIZE="$(($ARCHIVE_SIZE + $(eval printf -- "%b" "\$${ARCHIVE}_SIZE")))"
	fi

	# set package version
	if [ -n "$(eval printf -- "%b" "\$${ARCHIVE}_VERSION")" ]; then
		PKG_VERSION="$(eval printf -- "%b" "\$${ARCHIVE}_VERSION")+${script_version}"
	fi

	# check file integrity
	if [ -n "$(eval printf -- "%b" "\$${ARCHIVE}_MD5")" ]; then
		file_checksum "$file"
	fi
}

# try to guess archive type from file name
# USAGE: archive_guess_type $file
# CALLS: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: set_archive_vars
archive_guess_type() {
	case "${1##*/}" in
		(*.deb)
			export ${ARCHIVE}_TYPE='debian'
		;;
		(setup_*.exe|patch_*.exe)
			export ${ARCHIVE}_TYPE='innosetup'
		;;
		(gog_*.sh)
			export ${ARCHIVE}_TYPE='mojosetup'
		;;
		(*.tar.gz|*.tgz)
			export ${ARCHIVE}_TYPE='tar.gz'
		;;
		(*.zip)
			export ${ARCHIVE}_TYPE='zip'
		;;
		(*)
			archive_guess_type_error
		;;
	esac
}

# display an error message telling the type of the target archive is not set
# USAGE: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: archive_guess_type
archive_guess_type_error() {
	print_error
	local string
	case "${LANG%_*}" in
		('fr')
			string='ARCHIVE_TYPE n’est pas défini pour %s\n'
		;;
		('en'|*)
			string='ARCHIVE_TYPE is not set for %s\n'
		;;
	esac
	printf "$string" "$ARCHIVE"
	return 1
}

# print archive use message
# USAGE: set_archive_print $file
# NEEDED VARS: (LANG)
# CALLED BY: set_archive_vars
set_archive_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Utilisation de %s\n'
		;;
		('en'|*)
			string='Using %s\n'
		;;
	esac
	printf "$string" "$1"
}

# check integrity of target file
# USAGE: file_checksum $file
# NEEDED VARS: ARCHIVE OPTION_CHECKSUM (LANG)
# CALLS: file_checksum_md5 liberror
file_checksum() {
	case "$OPTION_CHECKSUM" in
		('md5')
			file_checksum_md5 "$1"
		;;
		('none')
			return 0
		;;
		(*)
			liberror 'OPTION_CHECKSUM' 'file_checksum'
		;;
	esac
}

# check integrity of target file against MD5 control sum
# USAGE: file_checksum_md5 $file
# NEEDED VARS: ARCHIVE
# CALLS: file_checksum_print file_checksum_error
# CALLED BY: file_checksum
file_checksum_md5() {
	file_checksum_print "$1"
	FILE_MD5="$(md5sum "$1" | awk '{print $1}')"
	if [ "$FILE_MD5" = "$(eval printf -- "%b" "\$${ARCHIVE}_MD5")" ]; then
		return 0
	else
		file_checksum_error "$1"
		return 1
	fi
}

# print integrity check message
# USAGE: file_checksum_print $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Contrôle de l’intégrité de %s\n'
		;;
		('en'|*)
			string='Checking integrity of %s\n'
		;;
	esac
	printf "$string" "$(basename "$1")"
}

# print integrity check error message
# USAGE: file_checksum_error $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_error() {
	print_error
	local string1
	local string2
	case "${LANG%_*}" in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.\n'
			string2='Utilisez --checksum=none pour forcer son utilisation.\n'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.\n'
			string2='Use --checksum=none to force its use.\n'
		;;
	esac
	printf "$string1" "$(basename "$1")"
	printf "$string2"
}

