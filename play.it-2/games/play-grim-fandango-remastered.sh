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
# Grim Fandango Remastered
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170601.1

# Set game-specific variables

GAME_ID='grim-fandango'
GAME_NAME='Grim Fandango Remastered'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_grim_fandango_remastered_2.3.0.7.sh'
ARCHIVE_GOG_MD5='9c5d124c89521d254b0dc259635b2abe'
ARCHIVE_GOG_SIZE='6100000'
ARCHIVE_GOG_VERSION='1.4-gog2.3.0.7'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game/bin'
ARCHIVE_DOC2_FILES='./runtime-README.txt ./*License.txt'

ARCHIVE_GAME_PATH='data/noarch/game/bin'
ARCHIVE_GAME_FILES='./commentary.lab ./common-licenses ./controllerdef.txt ./CREDITS.LAB ./DATA000.LAB ./DATA001.LAB ./DATA002.LAB ./DATA003.LAB ./DATA004.LAB ./DATA006.LAB ./DATA007.LAB ./en_gagl088.lip ./FontsHD ./grim.de.tab ./grim.en.tab ./grim.es.tab ./GrimFandango ./grim.fr.tab ./grim.it.tab ./grim.pt.tab ./icon.png ./IMAGES.LAB ./IMAGESPATCH001.LAB ./libchore.so ./libLua.so ./libSDL2-2.0.so.1 ./MATERIALS.lab ./MATERIALSPATCH001.LAB ./MOVIE00.LAB ./MOVIE01.LAB ./MOVIE02.LAB ./MOVIE03.LAB ./MOVIE04.LAB ./MoviesHD ./patch_v2_or_v3_to_v4.bin ./patch_v4_to_v5.bin ./runtime-README.txt ./scripts ./TheoraPlaybackLibraryLicense.txt ./TheroaLicense.txt ./VOX0000.LAB ./VOX0001.LAB ./VOX0002.LAB ./VOX0003.LAB ./VOX0004.LAB ./x86 ./YEAR0MUS.LAB ./YEAR1MUS.LAB ./YEAR2MUS.LAB ./YEAR3MUS.LAB ./YEAR4MUS.LAB ./YEAR5MUS.LAB'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='./GrimFandango'
APP_MAIN_ICON='./icon.png'
APP_MAIN_ICON_RES='128x128'

PACKAGES_LIST='PKG_MAIN'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB='libc6, libstdc++6, libsdl2-2.0-0'
PKG_MAIN_DEPS_ARCH='lib32-sdl2'

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

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

organize_data 'DOC1' "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"
organize_data 'GAME' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME"/$APP_MAIN_ICON "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
