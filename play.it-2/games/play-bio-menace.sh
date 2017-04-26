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
# Bio Menace
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170426.2

# Set game-specific variables

GAME_ID='bio-menace'
GAME_NAME='Bio Menace'

ARCHIVE_GOG='gog_bio_menace_2.0.0.2.sh'
ARCHIVE_GOG_MD5='75167ee3594dd44ec8535b29b90fe4eb'
ARCHIVE_GOG_SIZE='14000'
ARCHIVE_GOG_VERSION='1.1-gog2.0.0.2'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*.pdf ./*.txt'

ARCHIVE_DOC2_PATH='data/noarch/data'
ARCHIVE_DOC2_FILES='./*.txt'

ARCHIVE_GAME_BIN_PATH='data/noarch/data'
ARCHIVE_GAME_BIN_FILES='./*.exe ./biopatch.zip'

ARCHIVE_GAME_DATA_PATH='data/noarch/data'
ARCHIVE_GAME_DATA_FILES='./*.bm*'

CONFIG_FILES='./*.conf ./config.*'
DATA_FILES='./SAVEGAM*'

APP_1_ID="${GAME_ID}-1"
APP_1_NAME="$GAME_NAME - 1"
APP_1_TYPE='dosbox'
APP_1_EXE='bmenace1.exe'

APP_2_ID="${GAME_ID}-2"
APP_2_NAME="$GAME_NAME - 2"
APP_2_TYPE='dosbox'
APP_2_EXE='bmenace2.exe'

APP_3_ID="${GAME_ID}-3"
APP_3_NAME="$GAME_NAME - 3"
APP_3_TYPE='dosbox'
APP_3_EXE='bmenace3.exe'

APP_ICON='data/noarch/support/icon.png'
APP_ICON_RES='256'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, dosbox"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID dosbox"

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

# Set source archive

set_source_archive 'ARCHIVE_GOG'
check_deps
file_checksum "$SOURCE_ARCHIVE"

# Extract game data

set_workdir 'PKG_BIN' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "$PKG_DATA_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_ICON" "$PKG_DATA_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin 'APP_1'
write_bin 'APP_2'
write_bin 'APP_3'

write_desktop 'APP_1'
write_desktop 'APP_2'
write_desktop 'APP_3'

# Build package

cat > "$postinst" << EOF
ln --symbolic ./$GAME_ID.png "$PATH_ICON/$APP_1_ID.png"
ln --symbolic ./$GAME_ID.png "$PATH_ICON/$APP_2_ID.png"
ln --symbolic ./$GAME_ID.png "$PATH_ICON/$APP_3_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$APP_1_ID.png"
rm "$PATH_ICON/$APP_2_ID.png"
rm "$PATH_ICON/$APP_3_ID.png"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN'
build_pkg      'PKG_BIN' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
