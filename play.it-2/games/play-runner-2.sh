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
# Runner2: Future Legend of Rhythm Alien
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

GAME_ID='runner-2'
GAME_NAME='Runner2: Future Legend of Rhythm Alien'

ARCHIVES_LIST='ARCHIVE_HUMBLE_32 ARCHIVE_HUMBLE_64'

ARCHIVE_HUMBLE_32='runner2_i386_1388171186.tar.gz'
ARCHIVE_HUMBLE_32_MD5='ea105bdcd486879fb99889b87e90eed5'
ARCHIVE_HUMBLE_32_SIZE='770000'
ARCHIVE_HUMBLE_32_VERSION='1.0-humble1388171186'

ARCHIVE_HUMBLE_64='runner2_amd64_1388171186.tar.gz'
ARCHIVE_HUMBLE_64_MD5='2f7ccdb675a63a5fc152514682e97480'
ARCHIVE_HUMBLE_64_SIZE='770000'
ARCHIVE_HUMBLE_64_VERSION='1.0-humble1388171186'

ARCHIVE_DOC_PATH='runner2-1.0'
ARCHIVE_DOC_FILES='./README*'

ARCHIVE_GAME_BIN_PATH='runner2-1.0/runner2'
ARCHIVE_GAME_BIN_FILES='./runner2 ./*.so'

ARCHIVE_GAME_DATA_PATH='runner2-1.0/runner2'
ARCHIVE_GAME_DATA_FILES='./Effects ./Fonts ./Gameplay ./Graphics ./Menus ./Models ./package.toc ./Runner2.png ./Shaders ./Sounds ./Textures'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='runner2'
APP_MAIN_ICON='./Runner2.png'
APP_MAIN_ICON_RES='48'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH_HUMBLE_32='32'
PKG_BIN_ARCH_HUMBLE_64='64'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libgcc1, zlib1g, libsdl1.2debian, libgl1-mesa-glx | libgl1"
PKG_BIN_DEPS_ARCH_HUMBLE_64="$PKG_DATA_ID zlib sdl libgl"
PKG_BIN_DEPS_ARCH_HUMBLE_32="$PKG_DATA_ID lib32-zlib lib32-sdl lib32-libgl"

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
set_standard_permissions "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_DATA'

case "$PKG_BIN_ARCH" in
	
	('32')
		cat > "$postinst" <<- EOF
		ln --symbolic 'libfmodevent-4.44.08.so' "$PATH_GAME/libfmodevent.so"
		ln --symbolic 'libfmodex-4.44.08.so' "$PATH_GAME/libfmodex.so"
		EOF
		
		cat > "$prerm" <<- EOF
		rm "$PATH_GAME/libfmodex.so" "$PATH_GAME/libfmodevent.so"
		EOF
	;;
	
	('64')
		cat > "$postinst" <<- EOF
		ln --symbolic 'libfmodevent64-4.44.07.so' "$PATH_GAME/libfmodevent64.so"
		ln --symbolic 'libfmodex64-4.44.07.so' "$PATH_GAME/libfmodex64.so"
		EOF
		
		cat > "$prerm" <<- EOF
		rm "$PATH_GAME/libfmodex64.so" "$PATH_GAME/libfmodevent64.so"
		EOF
	;;
	
esac

write_metadata 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
