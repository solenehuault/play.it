#!/bin/sh -e
set -o errexit

###
# Copyright (c) 2015-2017, Antoine Le Gonidec
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# This software is provided by the copyright holders and contributors "as is"
# and any express or implied warranties, including, but not limited to, the
# implied warranties of merchantability and fitness for a particular purpose
# are disclaimed. In no event shall the copyright holder or contributors be
# liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages (including, but not limited to, procurement of
# substitute goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise)
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
###

###
# Emperor: Rise of the Middle Kingdom
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170218.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='emperor-rise-of-the-middle-kingdom'
GAME_NAME='Emperor: Rise of the Middle Kingdom'

ARCHIVE_GOG='setup_emperor_rise_of_the_middle_kingdom_2.0.0.2.exe'
ARCHIVE_GOG_MD5='5e50e84c028a85eafe5dd5f2aa277fea'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='820000'
ARCHIVE_GOG_VERSION='1.0.1.0-gog2.0.0.2'
ARCHIVE_GOG_TYPE='inno'

ARCHIVE_DOC_PATH='app'
ARCHIVE_DOC_FILES='./*.txt ./*.pdf'
ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe ./binkw32.dll ./ijl10.dll ./mss32.dll ./sierrapt.dll'
ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./*.cfg ./*.eng ./*.inf ./audio ./binks ./campaigns ./cities ./data ./emperor.ini ./model ./mp3dec.asi ./mssds3dh.m3d ./mssrsx.m3d ./res ./save'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.cfg ./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./save'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID}-common.sh"

APP_MAIN_ID="$GAME_ID"
APP_MAIN_NAME="$GAME_NAME"
APP_MAIN_EXE='emperor.exe'
APP_MAIN_ICON='emperor.exe'
APP_MAIN_ICON_RES='16x16 32x32'
APP_MAIN_CAT='Game'

APP_EDIT_ID="${GAME_ID}_editor"
APP_EDIT_NAME="$GAME_NAME - Editor"
APP_EDIT_EXE='emperoredit.exe'
APP_EDIT_CAT='Game'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH='all'
PKG_DATA_DESC="$GAME_NAME - data
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN_ID="$GAME_ID"
PKG_BIN_ARCH='i386'
PKG_BIN_DEPS="$PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DESC="$GAME_NAME
 package built from GOG.com installer
 ./play.it script version $script_version"

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "$PLAYIT_LIB" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "$PLAYIT_LIB" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "$PLAYIT_LIB" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "$TARGET_LIB_VERSION"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi

. "${PLAYIT_LIB}"

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard $SCRIPT_DEPS_HARD
check_deps_soft $SCRIPT_DEPS_SOFT

printf '\n'
GAME_ARCHIVE1="$ARCHIVE_GOG"
set_target '1' 'gog.com'
ARCHIVE_MD5="$ARCHIVE_GOG_MD5"
ARCHIVE_TYPE="$ARCHIVE_GOG_TYPE"
ARCHIVE_UNCOMPRESSED_SIZE="$ARCHIVE_GOG_UNCOMPRESSED_SIZE"
PKG_VERSION="$ARCHIVE_GOG_VERSION"
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

game_mkdir 'PKG_TMPDIR'   "$(mktemp -u $GAME_ID.XXXXX)"                    "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_DATA_DIR' "${PKG_DATA_ID}_${PKG_VERSION}_${PKG_DATA_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN_DIR'  "${GAME_ID}_${PKG_VERSION}_${PKG_BIN_ARCH}"      "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'quiet' "$ARCHIVE_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
mkdir -p "${PKG_DATA_DIR}/DEBIAN"
mkdir -p "${PKG_BIN_DIR}/DEBIAN" "${PKG_BIN_DIR}${PATH_BIN}" "${PKG_BIN_DIR}${PATH_DESK}"

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'quiet'

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC_PATH"
	for file in $ARCHIVE_DOC_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_BIN_PATH"
	for file in $ARCHIVE_GAME_BIN_FILES; do
		mkdir -p   "${PKG_BIN_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_BIN_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_DATA_PATH"
	for file in $ARCHIVE_GAME_DATA_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_GAME}/$file"
	done
)

if [ "$NO_ICON" = '0' ]; then
	PKG1_DIR="$PKG_BIN_DIR"
	extract_icons "$APP_MAIN_ID" "$APP_MAIN_ICON" "$APP_MAIN_ICON_RES" "$PKG_TMPDIR"
fi

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/$APP_COMMON_ID"
write_bin_wine_cfg    "${PKG1_DIR}${PATH_BIN}/${GAME_ID}-winecfg"
write_bin_wine        "${PKG1_DIR}${PATH_BIN}/$APP_MAIN_ID" "$APP_MAIN_EXE" '' '' "$APP_MAIN_NAME"

write_desktop "$APP_MAIN_ID" "$APP_MAIN_NAME" "$APP_MAIN_NAME" "${PKG1_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "$APP_MAIN_CAT" 'wine'

printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "$PKG_DATA_DIR" "$PKG_DATA_ID" "$PKG_VERSION" "$PKG_DATA_ARCH" '' ''              '' "$PKG_DATA_DESC"
write_pkg_debian "$PKG_BIN_DIR"  "$PKG_BIN_ID"  "$PKG_VERSION" "$PKG_BIN_ARCH"  '' "$PKG_BIN_DEPS" '' "$PKG_BIN_DESC"

build_pkg "$PKG_DATA_DIR"  "$PKG_DATA_DESC"  "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_BIN_DIR" "$PKG_BIN_DESC" "$PKG_COMPRESSION" 'quiet'
print done

print_instructions "$PKG_BIN_DESC" "$PKG_DATA_DIR" "$PKG_BIN_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
