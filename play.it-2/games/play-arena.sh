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
# The Elder Scrolls: Arena
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170508.1

# Set game-specific variables

GAME_ID='arena'
GAME_NAME='The Elder Scrolls: Arena'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_tes_arena_2.0.0.5.exe'
ARCHIVE_GOG_MD5='ca5a894aa852f9dbb3ede787e51ec828'
ARCHIVE_GOG_SIZE='130000'
ARCHIVE_GOG_VERSION='1.07-gog2.0.0.5'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./*.pdf ./readme.txt'

ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./gog_eula.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.cfg ./*.exe ./*.inf ./*.ini'

ARCHIVE_GAME_DATA1_PATH='app'
ARCHIVE_GAME_DATA1_FILES='./*.65 ./*.ad ./*.adv ./*.bak ./*.bnk ./*.bsa ./*.cel ./*.cif ./*.clr ./*.col ./*.cpy ./*.dat ./*.flc ./*.gld ./*.ico ./*.img ./*.lgt ./*.lst ./*.me ./*.mif ./*.mnu ./*.ntz ./*.opl ./*.rci ./*.txt ./*.voc ./*.xfm ./cityintr ./citytxt ./extra ./speech'

ARCHIVE_GAME_DATA2_PATH='app/__support'
ARCHIVE_GAME_DATA2_FILES='./save'

GAME_IMAGE='.'
GAME_IMAGE_TYPE='cdrom'

DATA_DIRS='./save ./arena_cd'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='acd.exe'
APP_MAIN_OPTIONS='-Ssbpdig.adv -IOS220 -IRQS7 -DMAS1 -Mgenmidi.adv -IOM330 -IRQM2 -DMAM1'
APP_MAIN_PRERUN='d:'
APP_MAIN_ICON='goggame-1435828982.ico'
APP_MAIN_ICON_RES='16 32 48 256'

PACKAGES_LIST='PKG_DATA PKG_BIN'

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

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'       "$PATH_DOC"
organize_data 'DOC2'       "$PATH_DOC"
organize_data 'GAME_DATA1' "$PATH_GAME"
organize_data 'GAME_DATA2' "$PATH_GAME"

extract_and_sort_icons_from 'APP_MAIN'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'
sed -i "s/imgmount d $GAME_IMAGE -t iso -fs iso/mount d $GAME_IMAGE -t cdrom/" "${PKG_BIN_PATH}${PATH_BIN}/$GAME_ID"

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
