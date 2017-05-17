# check script dependencies
# USAGE: check_deps
# NEEDED VARS: ARCHIVE_TYPE, SCRIPT_DEPS, CHECKSUM_METHOD, PACKAGE_TYPE
# CALLS: check_deps_7z, check_deps_icon, check_deps_failed
check_deps() {
	case "$(eval echo \$${ARCHIVE}_TYPE)" in
		('innosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
		;;
		('nixstaller')
			SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
		;;
		('mojosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS bsdtar"
		;;
		('zip')
			SCRIPT_DEPS="$SCRIPT_DEPS unzip"
		;;
		('rar')
			SCRIPT_DEPS="$SCRIPT_DEPS unar"
		;;
		('tar.gz')
			SCRIPT_DEPS="$SCRIPT_DEPS gzip tar"
		;;
	esac
	if [ "$CHECKSUM_METHOD" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$PACKAGE_TYPE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'bmp' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS convert"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'ico' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS icotool"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			(*)
				if ! which $dep >/dev/null 2>&1; then
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
	if which 7zr >/dev/null 2>&1; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif which 7za >/dev/null 2>&1; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif which unar >/dev/null 2>&1; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_failed 'p7zip'
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_failed $command_name
# CALLED BY: check_deps, check_deps_7z
check_deps_failed() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf '%s est introuvable. Installez-le avant de lancer ce script.\n' "$1"
		;;
		('en'|*)
			printf '%s not found. Install it before running this script.\n' "$1"
		;;
	esac
	return 1
}

