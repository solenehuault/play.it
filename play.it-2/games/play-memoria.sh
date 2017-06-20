#!/bin/sh -e
set -o errexit

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
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
# Memoria
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170616.2

# Set game-specific variables

GAME_ID='memoria'
GAME_NAME='Memoria'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_memoria_2.0.0.3.exe'
ARCHIVE_GOG_MD5='847c7b5e27a287d6e0e17e63bfb14fff'
ARCHIVE_GOG_SIZE='9100000'
ARCHIVE_GOG_VERSION='1.36.0053-gog2.0.0.3'
ARCHIVE_GOG_PART1='setup_memoria_2.0.0.3-1.bin'
ARCHIVE_GOG_PART1_MD5='e656464607e4d8599d599ed5b6b29fca'
ARCHIVE_GOG_PART1_TYPE='innosetup'
ARCHIVE_GOG_PART2='setup_memoria_2.0.0.3-2.bin'
ARCHIVE_GOG_PART2_MD5='593d57e8022c65660394c5bc5a333fe8'
ARCHIVE_GOG_PART2_TYPE='innosetup'
ARCHIVE_GOG_PART3='setup_memoria_2.0.0.3-3.bin'
ARCHIVE_GOG_PART3_MD5='0f8ef0abab77f3885aa4f8f9e58611eb'
ARCHIVE_GOG_PART3_TYPE='innosetup'
ARCHIVE_GOG_PART4='setup_memoria_2.0.0.3-4.bin'
ARCHIVE_GOG_PART4_MD5='0935149a66284bdc13659beafed2575f'
ARCHIVE_GOG_PART4_TYPE='innosetup'
ARCHIVE_GOG_PART5='setup_memoria_2.0.0.3-5.bin'
ARCHIVE_GOG_PART5_MD5='5b85fb7fcb51599ee89b5d7371b87ee2'
ARCHIVE_GOG_PART5_TYPE='innosetup'
ARCHIVE_GOG_PART6='setup_memoria_2.0.0.3-6.bin'
ARCHIVE_GOG_PART6_MD5='c8712354bbd093b706f551e75b549061'
ARCHIVE_GOG_PART6_TYPE='innosetup'

ARCHIVE_DOC1_PATH='app/documents/licenses'
ARCHIVE_DOC1_FILES='./*.txt'

ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./*eula.txt'

ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./avcodec-54.dll ./avformat-54.dll ./avutil-52.dll ./banner.jpg ./characters ./config.ini ./data.vis ./documents ./folder.jpg ./gfw_high.ico ./goggame.dll ./languages.xml ./libsndfile-1.dll ./lua ./memoria.exe ./openal32.dll ./scenes ./sdl2.dll ./swresample-0.dll ./swscale-2.dll ./videos ./visionaireconfigurationtool.exe ./zlib1.dll'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='memoria.exe'
APP_MAIN_ICON='gfw_high.ico'
APP_MAIN_ICON_RES='16 32 48 256'

PACKAGES_LIST='PKG_MAIN'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB='wine32-development | wine32 | wine-bin | wine-i386 | wine-staging-i386, wine:amd64 | wine'
PKG_MAIN_DEPS_ARCH='wine'

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

# Check that all parts of the installer are present

set_archive 'ARCHIVE_PART1' 'ARCHIVE_GOG_PART1'
[ "$ARCHIVE_PART1" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART1'
set_archive 'ARCHIVE_PART2' 'ARCHIVE_GOG_PART2'
[ "$ARCHIVE_PART2" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART2'
set_archive 'ARCHIVE_PART3' 'ARCHIVE_GOG_PART3'
[ "$ARCHIVE_PART3" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART3'
set_archive 'ARCHIVE_PART4' 'ARCHIVE_GOG_PART4'
[ "$ARCHIVE_PART4" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART4'
set_archive 'ARCHIVE_PART5' 'ARCHIVE_GOG_PART5'
[ "$ARCHIVE_PART5" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART5'
set_archive 'ARCHIVE_PART6' 'ARCHIVE_GOG_PART6'
[ "$ARCHIVE_PART6" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART6'
ARCHIVE='ARCHIVE_GOG'

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

organize_data 'DOC1' "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"
organize_data 'GAME' "$PATH_GAME"

extract_and_sort_icons_from 'APP_MAIN'
rm "${PKG_MAIN_PATH}${PATH_GAME}/$APP_MAIN_ICON"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
