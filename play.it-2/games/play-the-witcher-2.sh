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
# The Witcher 2
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170405.1

# Set game-specific variables

GAME_ID='the-witcher-2'
GAME_NAME='The Witcher 2: Assassins Of Kings'

ARCHIVE_GOG='gog_the_witcher_2_assassins_of_kings_enhanced_edition_2.2.0.8.sh'
ARCHIVE_GOG_MD5='3fff5123677a7be2023ecdb6af3b82b6'
ARCHIVE_GOG_SIZE='24000000'
ARCHIVE_GOG_VERSION='1release3-gog2.2.0.8'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'
ARCHIVE_DOC2_PATH='data/noarch/game'
ARCHIVE_DOC2_FILES='./*.rtf ./*.txt'
ARCHIVE_GAME_MAIN_PATH='data/noarch/game'
ARCHIVE_GAME_MAIN_FILES='./*'
ARCHIVE_GAME_PACK1_PATH='data/noarch/game'
ARCHIVE_GAME_PACK1_FILES='./CookedPC/pack0.dzip.split00'
ARCHIVE_GAME_PACK2_PATH='data/noarch/game'
ARCHIVE_GAME_PACK2_FILES='./CookedPC/pack0.dzip.split01 ./CookedPC/pack0.dzip.split02'
ARCHIVE_GAME_MOVIES_PATH='data/noarch/game'
ARCHIVE_GAME_MOVIES_FILES='./CookedPC/movies'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='./witcher2'
APP_MAIN_ICON='linux/icons/witcher2-icon.png'
APP_MAIN_ICON_RES='256x256'

APP_CONFIG_ID="${GAME_ID}_config"
APP_CONFIG_TYPE='native'
APP_CONFIG_EXE='./configurator'
APP_CONFIG_NAME="$GAME_NAME - configuration"
APP_CONFIG_ICON='linux/icons/witcher2-configurator.png'
APP_CONFIG_ICON_RES='256x256'
APP_CONFIG_CAT='Settings'

PKG_PACK1_ID="${GAME_ID}-pack1"
PKG_PACK1_DESCRIPTION='pack0, part 1'

PKG_PACK2_ID="${GAME_ID}-pack2"
PKG_PACK2_DESCRIPTION='pack0, part 2'

PKG_MOVIES_ID="${GAME_ID}-movies"
PKG_MOVIES_DESCRIPTION='movies'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB="$PKG_PACK1_ID, $PKG_PACK2_ID, $PKG_MOVIES_ID, libasound2-plugins, libgtk2.0-0, libsdl2-image-2.0-0, libfreetype6, libcurl3, libtxc-dxtn-s2tc0 | libtxc-dxtn0, libudev1"
PKG_MAIN_DEPS_ARCH="$PKG_PACK1_ID $PKG_PACK2_ID $PKG_MOVIES_ID lib32-alsa-lib lib32-gtk2 lib32-sdl2_image lib32-freetype2 lib32-curl lib32-libtxc_dxtn"

# Load common functions

target_version='2.0'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"
	if [ -e "$XDG_DATA_HOME/play.it/libplayit2.sh" ]; then
		PLAYIT_LIB2="$XDG_DATA_HOME/play.it/libplayit2.sh"
	elif [ -e './libplayit2.sh' ]; then
		PLAYIT_LIB2='./libplayit2.sh'
	else
		printf '\n\033[1;31mError:\033[0m\n'
		printf 'libplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

if [ ${library_version%.*} -ne ${target_version%.*} ] || [ ${library_version#*.} -lt ${target_version#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'wrong version of libplayit2.sh\n'
	printf 'target version is: %s\n' "$target_version"
	return 1
fi

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_MAIN' 'PKG_PACK1' 'PKG_PACK2' 'PKG_MOVIES'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_PACK1'
organize_data 'GAME_PACK1' "$PATH_GAME"

PKG='PKG_PACK2'
organize_data 'GAME_PACK2' "$PATH_GAME"

PKG='PKG_MOVIES'
organize_data 'GAME_MOVIES' "$PATH_GAME"

PKG='PKG_MAIN'
organize_data 'DOC1' "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"
organize_data 'GAME_MAIN' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_bin 'APP_MAIN' 'APP_CONFIG'
write_desktop 'APP_MAIN' 'APP_CONFIG'

# Build package

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
ln --symbolic "$PATH_GAME/$APP_CONFIG_ICON" "$PATH_ICON/$APP_CONFIG_ID.png"
printf 'Building pack0.dzip, this might take a while…\n'
cat "$PATH_GAME/CookedPC/pack0.dzip.split"* > "$PATH_GAME/CookedPC/pack0.dzip"
rm "$PATH_GAME/CookedPC/pack0.dzip.split"*
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rm "$PATH_ICON/$APP_CONFIG_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
rm "$PATH_GAME/CookedPC/pack0.dzip"
EOF

write_metadata 'PKG_MAIN'
rm "$postinst" "$prerm"
write_metadata 'PKG_PACK1' 'PKG_PACK2' 'PKG_MOVIES'

build_pkg 'PKG_MAIN' 'PKG_PACK1' 'PKG_PACK2' 'PKG_MOVIES'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_PACK2_PKG" "$PKG_PACK1_PKG" "$PKG_MOVIES_PKG" "$PKG_MAIN_PKG"

exit 0
