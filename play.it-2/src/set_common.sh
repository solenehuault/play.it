# set default values for common vars
# USAGE: set_common_defaults
set_common_defaults() {
	DEFAULT_CHECKSUM_METHOD='md5'
	DEFAULT_COMPRESSION_METHOD='none'
	DEFAULT_GAME_LANG='en'
	DEFAULT_GAME_LANG_AUDIO='en'
	DEFAULT_GAME_LANG_TXT='en'
	DEFAULT_INSTALL_PREFIX='/usr/local'
	DEFAULT_ICON_CHOICE='original'
	DEFAULT_MOVIES_SUPPORT='0'
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
	# Fall back on deb format by default
	if ! [ "$DEFAULT_PACKAGE_TYPE" ]; then
		DEFAULT_PACKAGE_TYPE='deb'
	fi
}

# set package paths
# USAGE: set_common_paths
# NEEDED VARS: PACKAGE_TYPE
# CALLS: set_common_paths_arch, set_common_paths_deb, set_common_paths_tar, liberror
set_common_paths() {
	case $PACKAGE_TYPE in
		('arch')
			set_common_paths_arch
		;;
		('deb')
			set_common_paths_deb
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'set_common_paths'
		;;
	esac
}

# set .pkg.tar.xz package paths
# USAGE: set_common_paths_arch
# NEEDED VARS: INSTALL_PREFIX, GAME_ID
# CALLED BY: set_common_paths
set_common_paths_arch() {
	PATH_BIN="${INSTALL_PREFIX}/bin"
	PATH_DESK='/usr/local/share/applications'
	PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
	PATH_GAME="${INSTALL_PREFIX}/share/${GAME_ID}"
	PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

# set .deb package paths
# USAGE: set_common_paths_deb
# NEEDED VARS: INSTALL_PREFIX, GAME_ID
# CALLED BY: set_common_paths
set_common_paths_deb() {
	PATH_BIN="${INSTALL_PREFIX}/games"
	PATH_DESK='/usr/local/share/applications'
	PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
	PATH_GAME="${INSTALL_PREFIX}/share/games/${GAME_ID}"
	PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

