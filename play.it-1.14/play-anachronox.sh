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
# Anachronox
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170204.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool'

GAME_ID='anachronox'
GAME_NAME='Anachronox'

GAME_ARCHIVE1='setup_anachronox_2.0.0.28.exe'
GAME_ARCHIVE1_MD5='a9e148972e51a4980a2531d12a85dfc0'
GAME_ARCHIVE1_TYPE='inno'
GAME_ARCHIVE1_UNCOMPRESSED_SIZE='1100000'
GAME_ARCHIVE1_VERSION='1.02build46-gog2.0.0.28'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='anoxdata/logs anoxdata/save'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='./anox.log anoxdata/nokill.*'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./*.rtf ./*.txt ./manual.pdf ./readme.htm'
ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./*eula.txt'
ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./afscmd.exe ./anachronox_word.jpg ./anoxaux.dll ./anoxdata ./anox.exe ./anoxgfx.dll ./anox.ico ./autorun.exe ./autorun.inf ./dparse.exe ./gamex86.dll ./gct?setup.exe ./gct?setup.ini ./ijl15.dll ./libpng13a.dll ./metagl.dll ./mscomctl.ocx ./mss32.dll ./msvcp60.dll ./msvcrt.dll ./particleman.exe ./patch.dll ./ref_gl.dll ./setupanox.exe ./zlib.dll'

APP_COMMON_ID="${GAME_ID}_common"

APP1_EXE='./anox.exe'
APP1_ICON='./anox.ico'
APP1_ICON_RES='16x16 32x32 48x48'
APP1_CAT='Game'

PKG_MAIN_ARCH='i386'
PKG_MAIN_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_MAIN_DESC="$GAME_NAME
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
	printf 'but lower than %s.\n\n' "$(( ${TARGET_LIB_VERSION%.*} + 1 )).0"
	exit 1
fi

. "$PLAYIT_LIB"

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
set_target '1' 'gog.com'
printf '\n'

game_mkdir 'PKG_TMPDIR'   "$(mktemp -u $GAME_ID.XXXXX)"                          "$(( $GAME_ARCHIVE1_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_MAIN_DIR' "${GAME_ID}_${GAME_ARCHIVE1_VERSION}_${PKG_MAIN_ARCH}" "$(( $GAME_ARCHIVE1_UNCOMPRESSED_SIZE * 2 ))"

PATH_BIN="$PKG_PREFIX/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="$PKG_PREFIX/share/doc/$GAME_ID"
PATH_GAME="$PKG_PREFIX/share/games/$GAME_ID"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$GAME_ARCHIVE1_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
rm -rf "$PKG_MAIN_DIR"
for dir in '/DEBIAN' "$PATH_BIN" "$PATH_DESK"; do
	mkdir -p "$PKG_MAIN_DIR/$dir"
done

extract_data "$GAME_ARCHIVE1_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'quiet,tolower'

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC1_PATH"
	for file in $ARCHIVE_DOC1_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC2_PATH"
	for file in $ARCHIVE_DOC2_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_PATH"
	for file in $ARCHIVE_GAME_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_GAME}/$file"
	done
)

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="$PKG_MAIN_DIR"
	extract_icons "$GAME_ID" "$APP1_ICON" "$APP1_ICON_RES" "$PKG_TMPDIR"
fi

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_wine_common "${PKG_MAIN_DIR}${PATH_BIN}/$APP_COMMON_ID"
write_bin_wine_cfg    "${PKG_MAIN_DIR}${PATH_BIN}/${GAME_ID}_winecfg"
write_bin_wine        "${PKG_MAIN_DIR}${PATH_BIN}/$GAME_ID" "$APP1_EXE" '' '' "$GAME_NAME"

write_desktop "$GAME_ID" "$GAME_NAME" "$GAME_NAME" "${PKG_MAIN_DIR}${PATH_DESK}/$GAME_ID.desktop" "$APP1_CAT" 'wine'

printf '\n'

# Build package

write_pkg_debian "$PKG_MAIN_DIR" "$GAME_ID" "$GAME_ARCHIVE1_VERSION" "$PKG_MAIN_ARCH" '' "$PKG_MAIN_DEPS" '' "$PKG_MAIN_DESC"
build_pkg        "$PKG_MAIN_DIR" "$PKG_MAIN_DESC" "$PKG_COMPRESSION"

print_instructions "$PKG_MAIN_DESC" "$PKG_MAIN_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
