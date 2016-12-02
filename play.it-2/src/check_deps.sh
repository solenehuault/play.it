# check script dependencies
# USAGE: check_deps
# NEEDED VARS: ARCHIVE_TYPE, SCRIPT_DEPS, CHECKSUM_METHOD, PACKAGE_TYPE
# CALLS: check_deps_7z, check_deps_icon, check_deps_failed
check_deps() {
	case "$ARCHIVE_TYPE" in
		('innosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
		;;
		('nixstaller')
			SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
		;;
		('mojosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS unzip"
		;;
		('zip')
			SCRIPT_DEPS="$SCRIPT_DEPS unzip"
		;;
		('rar')
			SCRIPT_DEPS="$SCRIPT_DEPS unar"
		;;
	esac
	if [ "$CHECKSUM_METHOD" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$PACKAGE_TYPE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'ico' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS icotool"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			('convert'|'icotool'|'wrestool')
				check_deps_icon "$dep"
			;;
			(*)
				if [ -z "$(which $dep)" ]; then
					check_deps_failed "$dep"
				fi
			;;
		esac
	done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# CALLS: check_deps_failed
# CALLED BY: check_deps
check_deps_7z() {
	if [ -n "$(which 7zr)" ]; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif [ -n "$(which 7za)" ]; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif [ -n "$(which unar)" ]; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_failed 'p7zip'
	fi
}

# check presence of a software to handle icon extraction
# USAGE: check_deps_icon $command_name
# NEEDED VARS: NO_ICON
# CALLED BY: check_deps
check_deps_icon() {
	if [ -z "$(which $1)" ] && [ "$NO_ICON" != '1' ]; then
		NO_ICON='1'
		case ${LANG%_*} in
			('fr')
				printf '%s est introuvable. Les icônes ne seront pas extraites.\n' "$1"
			;;
			('en'|*)
				printf '%s not found. Skipping icons extraction.\n' "$1"
			;;
		esac
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_failed $command_name
# CALLED BY: check_deps, check_deps_7z
check_deps_failed() {
	case ${LANG%_*} in
		('fr')
			printf "$string_error_fr\n"
			printf '%s est introuvable. Installez-le avant de lancer ce script.\n' "$1"
		;;
		('en'|*)
			printf "$string_error_en\n"
			printf '%s not found. Install it before running this script.\n' "$1"
		;;
	esac
	return 1
}

