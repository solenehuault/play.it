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
# Torment: Tides of Numenera
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170530.1

# Set game-specific variables

GAME_ID='torment-tides-of-numenera'
GAME_NAME='Torment: Tides of Numenera'

ARCHIVE_GOG='gog_torment_tides_of_numenera_2.3.0.4.sh'
ARCHIVE_GOG_MD5='839337b42a1618f3b445f363eca210d3'
ARCHIVE_GOG_TYPE='mojo'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='9300000'
ARCHIVE_GOG_VERSION='1.1.0-gog2.3.0.4'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./TidesOfNumenera ./TidesOfNumenera_Data/Mono/x86_64 ./TidesOfNumenera_Data/Plugins'

ARCHIVE_GAME_AUDIO_PATH='data/noarch/game'
ARCHIVE_GAME_AUDIO_FILES='./TidesOfNumenera_Data/StreamingAssets/Audio'

ARCHIVE_GAME_RESOURCES_PATH='data/noarch/game'
ARCHIVE_GAME_RESOURCES_FILES='./TidesOfNumenera_Data/resources.assets*'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./TidesOfNumenera_Data'

APP_MAIN_ID="$GAME_ID"
APP_MAIN_EXE='./TidesOfNumenera'
APP_MAIN_ICON='TidesOfNumenera_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'
APP_MAIN_NAME="$GAME_NAME"
APP_MAIN_CAT='Game'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_ARCH='all'
PKG_AUDIO_DESC="$GAME_NAME - audio
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_RESOURCES_ID="${GAME_ID}-resources"
PKG_RESOURCES_ARCH='all'
PKG_RESOURCES_DESC="$GAME_NAME - resources
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH='all'
PKG_DATA_DESC="$GAME_NAME - data
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN_ID="$GAME_ID"
PKG_BIN_ARCH='amd64'
PKG_BIN_DEPS="$PKG_AUDIO_ID, $PKG_RESOURCES_ID, $PKG_DATA_ID, libgl1-mesa-glx | libgl1, libsdl2-2.0-0"
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
	printf 'but lower than %s.\n\n' "$(( ${TARGET_LIB_VERSION%.*} + 1 )).0"
	exit 1
fi

. "$PLAYIT_LIB"

# Set extra variables

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard $SCRIPT_DEPS_HARD

printf '\n'
GAME_ARCHIVE1="$ARCHIVE_GOG"
set_target '1' 'gog.com'
ARCHIVE_MD5="$ARCHIVE_GOG_MD5"
ARCHIVE_TYPE="$ARCHIVE_GOG_TYPE"
ARCHIVE_UNCOMPRESSED_SIZE="$ARCHIVE_GOG_UNCOMPRESSED_SIZE"
PKG_VERSION="$ARCHIVE_GOG_VERSION"
printf '\n'

PATH_BIN="$PKG_PREFIX/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/$GAME_ID"
PATH_GAME="$PKG_PREFIX/share/games/$GAME_ID"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR'        "$(mktemp -u $GAME_ID.XXXXX)"                              "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_AUDIO_DIR'     "${PKG_AUDIO_ID}_${PKG_VERSION}_${PKG_AUDIO_ARCH}"         "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_RESOURCES_DIR' "${PKG_RESOURCES_ID}_${PKG_VERSION}_${PKG_RESOURCES_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_DATA_DIR'      "${PKG_DATA_ID}_${PKG_VERSION}_${PKG_DATA_ARCH}"           "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN_DIR'       "${PKG_BIN_ID}_${PKG_VERSION}_${PKG_BIN_ARCH}"             "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$ARCHIVE_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
mkdir -p "${PKG_AUDIO_DIR}/DEBIAN"
mkdir -p "${PKG_RESOURCES_DIR}/DEBIAN"
mkdir -p "${PKG_DATA_DIR}/DEBIAN"
mkdir -p "${PKG_BIN_DIR}/DEBIAN" "${PKG_BIN_DIR}${PATH_BIN}" "${PKG_BIN_DIR}${PATH_DESK}"

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'fix_rights,quiet'

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_BIN_PATH"
	for file in $ARCHIVE_GAME_BIN_FILES; do
		mkdir -p   "${PKG_BIN_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_BIN_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_AUDIO_PATH"
	for file in $ARCHIVE_GAME_AUDIO_FILES; do
		mkdir -p   "${PKG_AUDIO_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_AUDIO_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_RESOURCES_PATH"
	for file in $ARCHIVE_GAME_RESOURCES_FILES; do
		mkdir -p   "${PKG_RESOURCES_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_RESOURCES_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_DATA_PATH"
	for file in $ARCHIVE_GAME_DATA_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_GAME}/$file"
	done
	cd "$PKG_TMPDIR/$ARCHIVE_DOC_PATH"
	for file in $ARCHIVE_DOC_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_DOC}/$file"
	done
)

chmod 755 "${PKG_BIN_DIR}${PATH_GAME}/$APP_MAIN_EXE"

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_native "${PKG_BIN_DIR}${PATH_BIN}/$APP_MAIN_ID" "$APP_MAIN_EXE" '' '' '' "$APP_MAIN_NAME"

write_desktop "$APP_MAIN_ID" "$APP_MAIN_NAME" "$APP_MAIN_NAME" "${PKG_BIN_DIR}${PATH_DESK}/$APP_MAIN_ID.desktop" "$APP_MAIN_CAT"

printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "$PKG_BIN_DIR"       "$PKG_BIN_ID"       "$PKG_VERSION" "$PKG_BIN_ARCH"       '' "$PKG_BIN_DEPS" '' "$PKG_BIN_DESC"
write_pkg_debian "$PKG_RESOURCES_DIR" "$PKG_RESOURCES_ID" "$PKG_VERSION" "$PKG_RESOURCES_ARCH" '' ''              '' "$PKG_RESOURCES_DESC"
write_pkg_debian "$PKG_AUDIO_DIR"     "$PKG_AUDIO_ID"     "$PKG_VERSION" "$PKG_AUDIO_ARCH"     '' ''              '' "$PKG_AUDIO_DESC"
write_pkg_debian "$PKG_DATA_DIR"      "$PKG_DATA_ID"      "$PKG_VERSION" "$PKG_DATA_ARCH"      '' ''              '' "$PKG_DATA_DESC"

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"

file="$PKG_DATA_DIR/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$APP_MAIN_ID.png"
exit 0
EOF
chmod 755 "$file"

file="$PKG_DATA_DIR/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e
rm "$PATH_ICON/$APP_MAIN_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
exit 0
EOF
chmod 755 "$file"

build_pkg "$PKG_BIN_DIR"       "$PKG_BIN_DESC"       "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_RESOURCES_DIR" "$PKG_RESOURCES_DESC" "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_AUDIO_DIR"     "$PKG_AUDIO_DESC"     "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_DATA_DIR"      "$PKG_DATA_DESC"      "$PKG_COMPRESSION" 'quiet'
print done

print_instructions "$PKG_BIN_DESC" "$PKG_AUDIO_DIR" "$PKG_RESOURCES_DIR" "$PKG_DATA_DIR" "$PKG_BIN_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
