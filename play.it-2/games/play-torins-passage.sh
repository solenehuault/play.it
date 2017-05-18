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
# Torin’s Passage
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170518.2

# Set game-specific variables

GAME_ID='torins-passage'
GAME_NAME='Torin’s Passage'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_torins_passage_2.0.0.7.exe'
ARCHIVE_GOG_MD5='a7398abdb6964bf6a6446248f138d05e'
ARCHIVE_GOG_SIZE='348952'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.7'

ARCHIVE_DOC_PATH='app'
ARCHIVE_DOC_FILES='./torin.txt ./*.pdf'

ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./*.exe ./*.drv ./*.shp ./*.hlp ./*.scr ./install.txt ./movie ./patches ./*.000 ./*.aud ./resource.cfg ./*.sfx ./*.err ./version ./torinhr.ico'

DATA_FILES='./version ./AUTOSAVE.* ./TORINSG.*'
CONFIG_FILES='./resource.cfg ./TORIN.PRF'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='sierrah.exe'
APP_MAIN_OPTIONS='resource.cfg'
APP_MAIN_ICON='torinhr.ico'
APP_MAIN_ICON_RES='16 24 32 256'

PACKAGES_LIST='PKG_MAIN'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB='dosbox'
PKG_MAIN_DEPS_ARCH='dosbox'

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

organize_data 'DOC'  "$PATH_DOC"
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

print_instructions "$PKG_MAIN_PKG"

exit 0
