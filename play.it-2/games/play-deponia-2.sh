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
# Deponia 2 - Chaos on Deponia
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170329.1

# Set game-specific variables

GAME_ID='deponia-2'
GAME_NAME='Deponia 2 - Chaos on Deponia'

ARCHIVE_GOG='gog_deponia_2_chaos_on_deponia_2.1.0.3.sh'
ARCHIVE_GOG_MD5='7aa1251741a532e4b9f908a3af0d8f2a'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='3200000'
ARCHIVE_GOG_VERSION='3.3.2351-gog2.1.0.3'

ARCHIVE_HUMBLE='Deponia2_DEB_Full_3.2.2342_Multi_Daedalic_ESD.tar.gz'
ARCHIVE_HUMBLE_MD5='e7a71d5b8a83b2c2393095256b03553b'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='3100000'
ARCHIVE_HUMBLE_VERSION='3.2.2342-humble'

ARCHIVE_DOC_PATH_GOG='data/noarch/game'
ARCHIVE_DOC_PATH_HUMBLE='Chaos on Deponia'
ARCHIVE_DOC_FILES='./documents ./version.txt'

ARCHIVE_DOC2_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC2_FILES_GOG='./*'

ARCHIVE_GAME_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_PATH_HUMBLE='Chaos on Deponia'
ARCHIVE_GAME_FILES='./characters ./config.ini ./data.vis ./Deponia2 ./libs64 ./lua ./scenes ./videos'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Deponia2'
APP_MAIN_LIBS='libs64'
APP_MAIN_ICON_GOG='data/noarch/support/icon.png'
APP_MAIN_ICON_GOG_RES='256x256'

PKG_MAIN_ARCH='64'
PKG_MAIN_DEPS_DEB="libc6, libstdc++6, libgl1-mesa-glx | libgl1, libopenal1, libavcodec56 | libavcodec-ffmpeg56 | libavcodec-extra-56 | libavcodec-ffmpeg-extra56, libavformat56 | libavformat-ffmpeg56, libavutil54 | libavutil-ffmpeg54, libswscale3 | libswscale-ffmpeg3"
PKG_MAIN_DEPS_ARCH="libgl openal ffmpeg ffmpeg2.8"

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

set_source_archive 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'

case "$ARCHIVE" in
	
	('ARCHIVE_GOG')
		ARCHIVE_DOC_PATH="$ARCHIVE_DOC_PATH_GOG"
		ARCHIVE_DOC2_PATH="$ARCHIVE_DOC2_PATH_GOG"
		ARCHIVE_GAME_PATH="$ARCHIVE_GAME_PATH_GOG"
		APP_MAIN_ICON="$APP_MAIN_ICON_GOG"
		APP_MAIN_ICON_RES="$APP_MAIN_ICON_GOG_RES"
	;;
	
	('ARCHIVE_HUMBLE')
		ARCHIVE_DOC_PATH="$ARCHIVE_DOC_PATH_HUMBLE"
		unset ARCHIVE_DOC2_PATH
		ARCHIVE_GAME_PATH="$ARCHIVE_GAME_PATH_HUMBLE"
		unset APP_MAIN_ICON
		unset APP_MAIN_ICON_RES
	;;
	
esac

check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
check_deps

# Extract game data

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"
if [ "$ARCHIVE_TYPE" = 'tar' ]; then
	fix_rights "$PLAYIT_WORKDIR/gamedata"
fi

organize_data 'DOC'  "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"
organize_data 'GAME' "$PATH_GAME"

if [ "$APP_MAIN_ICON" ]; then
	PATH_ICON="${PKG_MAIN_PATH}${PATH_ICON_BASE}/$APP_MAIN_ICON_RES/apps"
	mkdir --parents "$PATH_ICON"
	mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
