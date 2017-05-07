# Check library version against script target version

library_version_major=${library_version%.*}
target_version_major=${target_version%.*}

library_version_minor=$(echo $library_version | cut -d'.' -f2)
target_version_minor=$(echo $target_version | cut -d'.' -f2)

if [ $library_version_major -ne $target_version_major ] || [ $library_version_minor -lt $target_version_minor ]; then
	case ${LANG%_*} in
		('fr')
			printf '\n\033[1;31mErreur:\033[0m\n'
			printf 'Mauvaise version de libplayit2.sh\n'
			printf 'La version cible est : %s\n' "$target_version"
		;;
		('en'|*)
			printf '\n\033[1;31mError:\033[0m\n'
			printf 'Wrong version of libplayit2.sh\n'
			printf 'Target version is: %s\n' "$target_version"
		;;
	esac
	return 1
fi

# Set default values for common vars

DEFAULT_CHECKSUM_METHOD='md5'
DEFAULT_COMPRESSION_METHOD='none'
DEFAULT_INSTALL_PREFIX='/usr/local'
DEFAULT_PACKAGE_TYPE='deb'
unset winecfg_desktop
unset winecfg_launcher

# Try to detect the host distribution through lsb_release

if [ $(which lsb_release 2>/dev/null 2>&1) ]; then
	case "$(lsb_release -si)" in
		('Debian'|'Ubuntu')
			DEFAULT_PACKAGE_TYPE='deb'
		;;
		('Arch')
			DEFAULT_PACKAGE_TYPE='arch'
		;;
	esac
fi

# Parse arguments given to the script

unset CHECKSUM_METHOD
unset COMPRESSION_METHOD
unset INSTALL_PREFIX
unset PACKAGE_TYPE
unset SOURCE_ARCHIVE
for arg in "$@"; do
	case "$arg" in
		('--checksum='*)
			export CHECKSUM_METHOD="${arg#*=}"
		;;
		('--compression='*)
			export COMPRESSION_METHOD="${arg#*=}"
		;;
		('--prefix='*)
			export INSTALL_PREFIX="${arg#*=}"
		;;
		('--package='*)
			export PACKAGE_TYPE="${arg#*=}"
		;;
		('--'*)
			return 1
		;;
		(*)
			export SOURCE_ARCHIVE="$arg"
		;;
	esac
done

# Set global variables not already set by script arguments

for var in 'CHECKSUM_METHOD' 'COMPRESSION_METHOD' 'INSTALL_PREFIX' 'PACKAGE_TYPE'; do
	value="$(eval echo \$$var)"
	if [ -z "$value" ]; then
		value_default="$(eval echo \$DEFAULT_$var)"
		if [ -n "$value_default" ]; then
			export $var="$value_default"
		fi
	fi
done
unset value
unset value_default

# Check script dependencies

check_deps

# Set package paths

case $PACKAGE_TYPE in
	('arch')
		PATH_BIN="$INSTALL_PREFIX/bin"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$INSTALL_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$INSTALL_PREFIX/share/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	('deb')
		PATH_BIN="$INSTALL_PREFIX/games"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$INSTALL_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$INSTALL_PREFIX/share/games/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	(*)
		return 1
	;;
esac

# Set source archive

set_source_archive $ARCHIVES_LIST

# Set working directories

set_workdir $PACKAGES_LIST


