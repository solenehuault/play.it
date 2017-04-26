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

