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

