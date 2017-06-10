# Check library version against script target version

library_version_major=${library_version%.*}
target_version_major=${target_version%.*}

library_version_minor=$(echo $library_version | cut -d'.' -f2)
target_version_minor=$(echo $target_version | cut -d'.' -f2)

if [ $library_version_major -ne $target_version_major ] || [ $library_version_minor -lt $target_version_minor ]; then
	print_error
	case "${LANG%_*}" in
		('fr')
			string1='Mauvaise version de libplayit2.sh\n'
			string2='La version cible est : %s\n'
		;;
		('en'|*)
			string1='Wrong version of libplayit2.sh\n'
			string2='Target version is: %s\n'
		;;
	esac
	printf "$string1"
	printf "$string2" "$target_version"
	exit 1
fi

# Set default values for common vars

DEFAULT_OPTION_CHECKSUM='md5'
DEFAULT_OPTION_COMPRESSION='none'
DEFAULT_OPTION_PREFIX='/usr/local'
DEFAULT_OPTION_PACKAGE='deb'
unset winecfg_desktop
unset winecfg_launcher

# Try to detect the host distribution through lsb_release

if which lsb_release >/dev/null 2>&1; then
	case "$(lsb_release --id --short)" in
		('Debian'|'Ubuntu')
			DEFAULT_OPTION_PACKAGE='deb'
		;;
		('Arch')
			DEFAULT_OPTION_PACKAGE='arch'
		;;
	esac
fi

# Parse arguments given to the script

unset OPTION_CHECKSUM
unset OPTION_COMPRESSION
unset OPTION_PREFIX
unset OPTION_PACKAGE
unset SOURCE_ARCHIVE

while [ $# -gt 0 ]; do
	case "$1" in
		('--help')
			help
			exit 0
		;;
		('--checksum='*|\
		'--checksum'|\
		'--compression='*|\
		'--compression'|\
		'--prefix='*|\
		'--prefix'|\
		'--package='*|\
		'--package')
			if [ "${1%=*}" != "${1#*=}" ]; then
				option="$(echo "${1%=*}" | sed 's/^--//')"
				value="${1#*=}"
			else
				option="$(echo "$1" | sed 's/^--//')"
				value="$2"
				shift 1
			fi
			if [ "$value" = 'help' ]; then
				eval help_$option
				exit 0
			else
				export OPTION_$(echo $option | tr [:lower:] [:upper:])="$value"
			fi
			unset option
			unset value
		;;
		('--'*)
			return 1
		;;
		(*)
			export SOURCE_ARCHIVE="$1"
		;;
	esac
	shift 1
done

# Set options not already set by script arguments to default values

for option in 'CHECKSUM' 'COMPRESSION' 'PREFIX' 'PACKAGE'; do
	if [ -z "$(eval echo \$OPTION_$option)" ] && [ -n "$(eval echo \$DEFAULT_OPTION_$option)" ]; then
		export OPTION_$option="$(eval echo \$DEFAULT_OPTION_$option)"
	fi
done

# Check script dependencies

check_deps

# Set package paths

case $OPTION_PACKAGE in
	('arch')
		PATH_BIN="$OPTION_PREFIX/bin"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$OPTION_PREFIX/share/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	('deb')
		PATH_BIN="$OPTION_PREFIX/games"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$OPTION_PREFIX/share/games/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	(*)
		liberror 'OPTION_PACKAGE' "$0"
	;;
esac

# Set source archive

set_source_archive $ARCHIVES_LIST

# Set working directories

set_temp_directories $PACKAGES_LIST


