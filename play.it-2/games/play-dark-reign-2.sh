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
# Dark Reign 2
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

GAME_ID='dark-reign-2'
GAME_NAME='Dark Reign 2'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_dark_reign2_2.0.0.11.exe'
ARCHIVE_GOG_MD5='9a3d10825507b73c4db178f9caea2406'
ARCHIVE_GOG_VERSION='1.3.882-gog2.0.0.11'
ARCHIVE_GOG_SIZE='450000'

ARCHIVE_DOC_PATH='app'
ARCHIVE_DOC_FILES='./customer_support.htm ./manual.pdf ./readme.rtf ./*.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./dr2.exe ./launcher.exe ./binkw32.dll ./getinfo.dll ./libogg-0.dll ./libvorbis-0.dll ./libvorbisfile-3.dll ./mss32.dll ./msvcp90.dll ./msvcr90.dll ./winmm.dll ./anet.inf ./library'

ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./missions ./mods ./music ./packs ./sides ./worlds'

CONFIG_FILES='./settings.cfg'
DATA_DIRS='./mods ./users'
DATA_FILES='./dr2.log'

APP_WINETRICKS='win98'

APP_MAIN_TYPE='wine'
APP_MAIN_PRERUN='regedit dr2-cdkey.reg'
APP_MAIN_EXE='launcher.exe'
APP_MAIN_ICON='dr2.exe'
APP_MAIN_ICON_RES='16 32'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, winetricks, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID winetricks wine"

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
organize_data 'GAME_DATA' "$PATH_GAME"
organize_data 'DOC'       "$PATH_DOC"

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN'
(
	cd "$PKG_BIN_PATH"
	cp --link --parents --recursive "./$PATH_ICON_BASE" "$PKG_DATA_PATH"
	rm --recursive "./$PATH_ICON_BASE"
	rmdir --ignore-fail-on-non-empty --parents "./${PATH_ICON_BASE%/*}"
)

cat > "${PKG_BIN_PATH}${PATH_GAME}/dr2-cdkey.reg" << EOF
REGEDIT4
[HKEY_LOCAL_MACHINE\Software\WON\CDKeys]
"DarkReign2"=hex:56,c1,0c,ed,bb,61,40,19,99,3d,cd,6c,78,51,4c,5e
EOF

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
