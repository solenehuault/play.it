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
}

set_common_paths() {
NO_ICON=0
case $PACKAGE_TYPE in
	deb) set_common_paths_deb ;;
	tar) set_common_paths_tar ;;
	*) liberror 'PACKAGE_TYPE' 'set_common_paths'
esac
}

set_common_paths_deb() {
PATH_BIN="${INSTALL_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${INSTALL_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

set_common_paths_tar() {
PATH_BIN="${INSTALL_PREFIX}/bin"
PATH_DESK="$INSTALL_PREFIX"
PATH_DOC="${INSTALL_PREFIX}/doc"
PATH_GAME="${INSTALL_PREFIX}/data"
PATH_ICON_BASE="${INSTALL_PREFIX}/icons"
}

