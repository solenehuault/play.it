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
DEFAULT_PACKAGE_TYPE='deb'
NO_ICON='0'
}

# set package paths
# USAGE: set_common_paths
# NEEDED VARS: PACKAGE_TYPE
# CALLS: set_common_paths_deb, set_common_paths_tar, liberror
set_common_paths() {
case $PACKAGE_TYPE in
	deb) set_common_paths_deb ;;
	tar) set_common_paths_tar ;;
	*) liberror 'PACKAGE_TYPE' 'set_common_paths'
esac
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

# set .tar archive paths
# USAGE: set_common_paths_tar
# NEEDED VARS: INSTALL_PREFIX
# CALLED BY: set_common_paths
set_common_paths_tar() {
PATH_BIN="${INSTALL_PREFIX}/bin"
PATH_DESK="$INSTALL_PREFIX"
PATH_DOC="${INSTALL_PREFIX}/doc"
PATH_GAME="${INSTALL_PREFIX}/data"
PATH_ICON_BASE="${INSTALL_PREFIX}/icons"
}

