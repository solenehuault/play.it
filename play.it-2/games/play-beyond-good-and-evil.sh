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
# Beyond Good and Evil
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170614.1

# Set game-specific variables

GAME_ID='beyond-good-and-evil'
GAME_NAME='Beyond Good and Evil'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_beyond_good_and_evil_2.1.0.9.exe'
ARCHIVE_GOG_MD5='fdfa4b94cf02e24523b01c9d54568482'
ARCHIVE_GOG_VERSION='1.0-gog2.1.0.9'
ARCHIVE_GOG_SIZE='2200000'

ARCHIVE_DOC1_PATH='tmp'
ARCHIVE_DOC1_FILES='./*eula.txt'

ARCHIVE_DOC2_PATH='app'
ARCHIVE_DOC2_FILES='./manual.pdf ./readme.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe'

ARCHIVE_GAME1_DATA_PATH='app'
ARCHIVE_GAME1_DATA_FILES='./bgemakingof.bik ./binkw32.dll ./jade.spe ./sally_clean.bf'

ARCHIVE_GAME2_DATA_PATH='sys'
ARCHIVE_GAME2_DATA_FILES='./eax.dll'

DATA_FILES='./sally.idx ./*.sav'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./run.exe'
APP_MAIN_ICON='./bge.exe'
APP_MAIN_ICON_RES='16 32 48'

APP_SETTINGS_TYPE='wine'
APP_SETTINGS_ID="${GAME_ID}_settings"
APP_SETTINGS_EXE='./settingsapplication.exe'
APP_SETTINGS_ICON='./settingsapplication.exe'
APP_SETTINGS_ICON_RES='16 32 48'
APP_SETTINGS_NAME="$GAME_NAME - settings"
APP_SETTINGS_CAT='Settings'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine-i386 | wine-staging-i386"
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
organize_data 'DOC1'       "$PATH_DOC"
organize_data 'DOC2'       "$PATH_DOC"
organize_data 'GAME1_DATA' "$PATH_GAME"
organize_data 'GAME2_DATA' "$PATH_GAME"

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN' 'APP_SETTINGS'
move_icons_to 'PKG_DATA'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN' 'APP_SETTINGS'

cat > "${PKG_BIN_PATH}${PATH_GAME}/bge.reg" << EOF
REGEDIT4

[HKEY_LOCAL_MACHINE\Software\Ubisoft\Beyond Good & Evil]
"Install path"="C:\\\beyond-good-and-evil"
EOF

sed --in-place 's#cp --force --recursive --symbolic-link --update "$PATH_GAME"/\* "$PATH_PREFIX"#&\n\tregedit "$PATH_PREFIX/bge.reg" 2>/dev/null#' "${PKG_BIN_PATH}${PATH_BIN}/$GAME_ID"
sed --in-place 's#cp --force --recursive --symbolic-link --update "$PATH_GAME"/\* "$PATH_PREFIX"#&\n\tregedit "$PATH_PREFIX/bge.reg" 2>/dev/null#' "${PKG_BIN_PATH}${PATH_BIN}/$APP_SETTINGS_ID"
sed --in-place 's#cp --force --recursive --symbolic-link --update "$PATH_GAME"/\* "$PATH_PREFIX"#&\n\tregedit "$PATH_PREFIX/bge.reg" 2>/dev/null#' "${PKG_BIN_PATH}${PATH_BIN}/$APP_WINECFG_ID"

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
