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
# Heroes of Might and Magic IV
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161230.2

# Set game-specific variables

GAME_ID='heroes-of-might-and-magic-4'
GAME_NAME='Heroes of Might and Magic IV'

ARCHIVE_GOG_EN='setup_homm4_complete_2.0.0.12.exe'
ARCHIVE_GOG_EN_MD5='74de66eb408bb2916dd0227781ba96dc'
ARCHIVE_GOG_EN_VERSION='3.0-gog2.0.0.12'
ARCHIVE_GOG_EN_UNCOMPRESSED_SIZE='1100000'

ARCHIVE_GOG_FR='setup_homm4_complete_french_2.1.0.14.exe'
ARCHIVE_GOG_FR_MD5='2af96eb28226e563bbbcd62771f3a319'
ARCHIVE_GOG_FR_VERSION='3.0-gog2.1.0.14'
ARCHIVE_GOG_FR_UNCOMPRESSED_SIZE='1100000'

ARCHIVE_DOC1_PATH='tmp'
ARCHIVE_DOC1_FILES='./*eula.txt'
ARCHIVE_DOC2_PATH='app'
ARCHIVE_DOC2_FILES='./*.chm ./*.pdf ./*.txt'
ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe ./binkw32.dll ./drvmgt.dll ./mss32.dll ./mp3dec.asi data/*.dll'
ARCHIVE_GAME_STORM_PATH='app'
ARCHIVE_GAME_STORM_FILES='data/storm_override.h4r data/storm.aop'
ARCHIVE_GAME_MUSIC_PATH='app'
ARCHIVE_GAME_MUSIC_FILES='data/music.h4r'
ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./data ./maps'

DATA_DIRS='./games ./maps'
DATA_FILES='./data/high_scores.dat ./*.log'

APP_WINETRICKS='ddr=gdi vd=1280x1024'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./heroes4.exe'
APP_MAIN_ICON='./heroes4.exe'
APP_MAIN_ICON_RES='16x16 32x32'

APP_EDITOR_TYPE='wine'
APP_EDITOR_ID="${GAME_ID}_edit"
APP_EDITOR_EXE='./campaign_editor.exe'
APP_EDITOR_ICON='./campaign_editor.exe'
APP_EDITOR_ICON_RES='48x48 64x64'
APP_EDITOR_NAME="$GAME_NAME - campaign editor"

PKG_STORM_ID="${GAME_ID}-storm"
PKG_STORM_DESCRIPTION='Gathering Storm'

PKG_MUSIC_ID="${GAME_ID}-music"
PKG_MUSIC_DESCRIPTION='music'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH_DEB='32on64'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, $PKG_MUSIC_ID, winetricks, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID $PKG_MUSIC_ID winetricks wine"

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

set_source_archive 'ARCHIVE_GOG_EN' 'ARCHIVE_GOG_FR'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG_EN' 'ARCHIVE_GOG_FR'
check_deps

# Extract game data

set_workdir 'PKG_BIN' 'PKG_STORM' 'PKG_MUSIC' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN'
organize_data_generic 'GAME_BIN' "$PATH_GAME"

PKG='PKG_STORM'
organize_data_generic 'GAME_STORM' "$PATH_GAME"

PKG='PKG_MUSIC'
organize_data_generic 'GAME_MUSIC' "$PATH_GAME"

PKG='PKG_DATA'
organize_data_generic 'GAME_DATA' "$PATH_GAME"
organize_data_generic 'DOC1'      "$PATH_DOC"
organize_data_generic 'DOC2'      "$PATH_DOC"

if [ "$NO_ICON" = '0' ]; then
	(
		cd "${PKG_BIN_PATH}${PATH_GAME}"

		extract_icon_from "$APP_MAIN_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_MAIN'
		rm --recursive "$PLAYIT_WORKDIR/icons"

		extract_icon_from "$APP_EDITOR_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_EDITOR'
		rm --recursive "$PLAYIT_WORKDIR/icons"
	)
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin     'APP_MAIN' 'APP_EDITOR'
write_desktop 'APP_MAIN' 'APP_EDITOR'

# Build package

write_metadata 'PKG_BIN' 'PKG_STORM' 'PKG_MUSIC' 'PKG_DATA'
build_pkg      'PKG_BIN' 'PKG_STORM' 'PKG_MUSIC' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_STORM_PKG" "$PKG_MUSIC_PKG" "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
