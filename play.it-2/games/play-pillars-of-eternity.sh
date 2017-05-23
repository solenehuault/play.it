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
# Pillars of Eternity
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

GAME_ID='pillars-of-eternity'
GAME_NAME='Pillars of Eternity'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_pillars_of_eternity_2.15.0.19.sh'
ARCHIVE_GOG_MD5='2000052541abb1ef8a644049734e8526'
ARCHIVE_GOG_SIZE='15000000'
ARCHIVE_GOG_VERSION='3.05.1186-gog2.15.0.19'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_GOG_DLC1='gog_pillars_of_eternity_kickstarter_item_dlc_2.0.0.2.sh'
ARCHIVE_GOG_DLC1_MD5='b4c29ae17c87956471f2d76d8931a4e5'

ARCHIVE_GOG_DLC2='gog_pillars_of_eternity_kickstarter_pet_dlc_2.0.0.2.sh'
ARCHIVE_GOG_DLC2_MD5='3653fc2a98ef578335f89b607f0b7968'

ARCHIVE_GOG_DLC3='gog_pillars_of_eternity_preorder_item_and_pet_dlc_2.0.0.2.sh'
ARCHIVE_GOG_DLC3_MD5='b86ad866acb62937d2127407e4beab19'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./PillarsOfEternity ./PillarsOfEternity_Data/Mono ./PillarsOfEternity_Data/Plugins'

ARCHIVE_GAME_AREA_PATH='data/noarch/game'
ARCHIVE_GAME_AREA_FILES='./PillarsOfEternity_Data/assetbundles/st_ar_*'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./PillarsOfEternity_Data ./PillarsOfEternity.png'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='PillarsOfEternity'
APP_MAIN_ICON1='./PillarsOfEternity.png'
APP_MAIN_ICON1_RES='512'
APP_MAIN_ICON2='./PillarsOfEternity_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON2_RES='128'

PACKAGES_LIST='PKG_AREA PKG_DATA PKG_BIN'

PKG_AREA_ID="${GAME_ID}-areas"
PKG_AREA_DESCRIPTION='area'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS_DEB="$PKG_AREA_ID, $PKG_DATA_ID, libglu1-mesa | libglu1, libxcursor1, libxrandr2"
PKG_BIN_DEPS_ARCH="$PKG_AREA_ID $PKG_DATA_ID glu libxcursor libxrandr"

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

# Load extra archives (DLC)

ARCHIVE_MAIN="$ARCHIVE"
set_archive 'ARCHIVE_DLC1' 'ARCHIVE_GOG_DLC1'
set_archive 'ARCHIVE_DLC2' 'ARCHIVE_GOG_DLC2'
set_archive 'ARCHIVE_DLC3' 'ARCHIVE_GOG_DLC3'
ARCHIVE="$ARCHIVE_MAIN"

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
(
	if [ "$ARCHIVE_DLC1" ]; then
		ARCHIVE='ARCHIVE_GOG_DLC1'
		extract_data_from "$ARCHIVE_DLC1"
	fi
	if [ "$ARCHIVE_DLC2" ]; then
		ARCHIVE='ARCHIVE_GOG_DLC2'
		extract_data_from "$ARCHIVE_DLC2"
	fi
	if [ "$ARCHIVE_DLC3" ]; then
		ARCHIVE='ARCHIVE_GOG_DLC3'
		extract_data_from "$ARCHIVE_DLC3"
	fi
)

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_AREA'
organize_data 'GAME_AREA' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON1_RES"
PATH_ICON1="$PATH_ICON_BASE/${res}x${res}/apps"

res="$APP_MAIN_ICON2_RES"
PATH_ICON2="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON1" "$PATH_ICON2"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON1" "$PATH_ICON1/$GAME_ID.png"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON2" "$PATH_ICON2/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON1/$GAME_ID.png" "$PATH_ICON2/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON1" "$PATH_ICON2"
EOF

write_metadata 'PKG_BIN'
rm "$postinst" "$prerm"
write_metadata 'PKG_AREA' 'PKG_DATA'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
