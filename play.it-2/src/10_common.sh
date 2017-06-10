# set package distribution-specific architecture
# USAGE: set_architecture $pkg
# CALLS: liberror set_architecture_arch set_architecture_deb
# NEEDED VARS: (ARCHIVE) (OPTION_PACKAGE) (PKG_ARCH)
# CALLED BY: set_temp_directories write_metadata
set_architecture() {
	local architecture
	if [ "$ARCHIVE" ] && [ -n "$(eval printf -- \"\$${1}_ARCH_${ARCHIVE#ARCHIVE_}\")" ]; then
		architecture="$(eval printf -- \"\$${1}_ARCH_${ARCHIVE#ARCHIVE_}\")"
		export ${1}_ARCH="$architecture"
	else
		architecture="$(eval printf -- \"\$${1}_ARCH\")"
	fi
	case $OPTION_PACKAGE in
		('arch')
			set_architecture_arch "$architecture"
		;;
		('deb')
			set_architecture_deb "$architecture"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'set_architecture'
		;;
	esac
}

# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	test "${1%%_*}" = "$2"
}

# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: set_standard_permissions $dir[…]
set_standard_permissions() {
	for dir in "$@"; do
		[  -d "$dir" ] || return 1
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

# print a localized error message
# USAGE: print_error
# NEEDED VARS: (LANG)
print_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Erreur :'
		;;
		('en'|*)
			string='Error:'
		;;
	esac
	printf '\n\033[1;31m%s\033[0m\n' "$string"
	exec 1>&2
}

# convert files name to lower case
# USAGE: tolower $dir[…]
tolower() {
	for dir in "$@"; do
		[ -d "$dir" ] || return 1
		find "$dir" -depth -mindepth 1 | while read file; do
			newfile="${file%/*}/$(echo "${file##*/}" | tr [:upper:] [:lower:])"
			[ -e "$newfile" ] || mv "$file" "$newfile"
		done
	done
}

# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
# NEEDED VARS: (LANG)
liberror() {
	local var="$1"
	local value="$(eval printf -- \"\$$var\")"
	local func="$2"
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Valeur incorrecte pour %s appelée par %s : %s\n'
		;;
		('en'|*)
			string='Invalid value for %s called by %s: %s\n'
		;;
	esac
	printf "$string" "$var" "$func" "$value"
	return 1
}

