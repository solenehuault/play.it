# check script dependencies
# USAGE: check_deps
# NEEDED VARS: ARCHIVE_TYPE, SCRIPT_DEPS, CHECKSUM_METHOD, PACKAGE_TYPE
# CALLS: check_deps_7z, check_deps_icon, check_deps_failed
check_deps() {
[ "$ARCHIVE_TYPE" = 'innosetup' ] && SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
[ "$ARCHIVE_TYPE" = 'nixstaller' ] && SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
[ "$ARCHIVE_TYPE" = 'mojosetup' ] && SCRIPT_DEPS="$SCRIPT_DEPS unzip"
[ "$ARCHIVE_TYPE" = 'zip' ] && SCRIPT_DEPS="$SCRIPT_DEPS unzip"
[ "$ARCHIVE_TYPE" = 'rar' ] && SCRIPT_DEPS="$SCRIPT_DEPS unar"
[ "$CHECKSUM_METHOD" = 'md5sum' ] && SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
[ "$PACKAGE_TYPE" = 'deb' ] && SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
for dep in $SCRIPT_DEPS; do
case $dep in
	7z) check_deps_7z ;;
	convert|icotool|wrestool) check_deps_icon "$dep" ;;
	*) [ -n "$(which $dep)" ] || check_deps_failed "$dep" ;;
esac
done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# CALLS: check_deps_failed
# CALLED BY: check_deps
check_deps_7z() {
if [ -n "$(which 7zr)" ]; then
	extract_7z() { 7zr x -o"$PLAYIT_WORKDIR" -y "$file"; }
elif [ -n "$(which 7za)" ]; then
	extract_7z() { 7za x -o"$PLAYIT_WORKDIR" -y "$file"; }
elif [ -n "$(which unar)" ]; then
	extract_7z() { unar -output-directory "$PLAYIT_WORKDIR" -force-overwrite -no-directory "$file"; }
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
		fr) echo "$1 est introuvable. Les icônes ne seront pas extraites." ;;
		en|*) echo "$1 not found. Skipping icons extraction." ;;
	esac
fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_failed $command_name
# CALLED BY: check_deps, check_deps_7z
check_deps_failed() {
case ${LANG%_*} in
	fr) echo "$string_error_fr\n$1 est introuvable. Installez-le avant de lancer ce script." ;;
	en|*) echo "$string_error_en\n$1 not found. Install it before running this script." ;;
esac
return 1
}

