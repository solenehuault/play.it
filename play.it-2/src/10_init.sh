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

