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
# Anachronox
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170504.1

# Set game-specific variables

GAME_ID='anachronox'
GAME_NAME='Anachronox'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_anachronox_2.0.0.28.exe'
ARCHIVE_GOG_MD5='a9e148972e51a4980a2531d12a85dfc0'
ARCHIVE_GOG_SIZE='1100000'
ARCHIVE_GOG_VERSION='1.02build46-gog2.0.0.28'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./*.rtf ./*.txt ./manual.pdf ./readme.htm'

ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./*eula.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./afscmd.exe ./anoxaux.dll ./anox.exe ./anoxgfx.dll ./autorun.exe ./autorun.inf ./dparse.exe ./gamex86.dll ./gct?setup.exe ./gct?setup.ini ./ijl15.dll ./libpng13a.dll ./metagl.dll ./mscomctl.ocx ./mss32.dll ./msvcp60.dll ./msvcrt.dll ./particleman.exe ./patch.dll ./ref_gl.dll ./setupanox.exe ./zlib.dll'

ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./anachronox_word.jpg ./anoxdata ./anox.ico'

DATA_DIRS='anoxdata/logs anoxdata/save'
DATA_FILES='./anox.log anoxdata/nokill.*'
CONFIG_FILES='./*.ini'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./anox.exe'
APP_MAIN_ICON='./anox.ico'
APP_MAIN_ICON_RES='16 32 48'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID wine"

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
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

extract_and_sort_icons_from 'APP_MAIN'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

write_metadata 'PKG_BIN' 'PKG_DATA'
build_pkg      'PKG_BIN' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
