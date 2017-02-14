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
# World of Goo
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170209.1

# Set game-specific variables

GAME_ID='world-of-goo'
GAME_NAME='World of Goo'

ARCHIVE_GOG='gog_world_of_goo_2.0.0.3.sh'
ARCHIVE_GOG_MD5='5359b8e7e9289fba4bcf74cf22856655'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='82000'
ARCHIVE_GOG_VERSION='1.41-gog2.0.0.3'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'
ARCHIVE_DOC2_PATH='data/noarch/game'
ARCHIVE_DOC2_FILES='./*.html ./*.txt'
ARCHIVE_GAME_32_PATH='data/noarch/game'
ARCHIVE_GAME_32_FILES='./WorldOfGoo.bin32 ./libs32'
ARCHIVE_GAME_64_PATH='data/noarch/game'
ARCHIVE_GAME_64_FILES='./WorldOfGoo.bin64 ./libs64'
ARCHIVE_GAME_MAIN_PATH='data/noarch/game'
ARCHIVE_GAME_MAIN_FILES='./icons ./properties ./res'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='WorldOfGoo.bin32'
APP_MAIN_EXE_64='WorldOfGoo.bin64'
APP_MAIN_ICON_RES='16x16 22x22 32x32 48x48 64x64 128x128'

PKG_MAIN_ID="${GAME_ID}-common"
PKG_MAIN_DESCRIPTION='arch-independant data'

PKG_32_ARCH='32'
PKG_32_CONFLICTS_DEB="$GAME_ID"
PKG_32_DEPS_DEB="$PKG_MAIN_ID, libglu1-mesa | libglu1, libogg0, libsdl1.2debian, libsdl-mixer1.2"
PKG_32_DEPS_ARCH="$PKG_MAIN_ID glu libogg sdl sdl2_mixer"

PKG_64_ARCH='64'
PKG_64_CONFLICTS_DEB="$GAME_ID"
PKG_64_DEPS_DEB="$PKG_32_DEPS_DEB"
PKG_64_DEPS_ARCH="$PKG_32_DEPS_ARCH"

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

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
PATH_ICON="$PKG_MAIN_PATH$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'

# Extract game data

set_workdir 'PKG_MAIN' 'PKG_32' 'PKG_64'
PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_32'
organize_data_generic 'GAME_32' "$PATH_GAME"
PKG='PKG_64'
organize_data_generic 'GAME_64' "$PATH_GAME"
PKG='PKG_MAIN'
organize_data_generic 'GAME_MAIN' "$PATH_GAME"
organize_data_generic 'DOC' "$PATH_DOC"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

cat > "$postinst" << EOF
for res in ${APP_MAIN_ICON_RES}; do
	PATH_ICON="${PATH_ICON_BASE}/\${res}/apps"
	mkdir -p "\${PATH_ICON}"
	ln -s "${PATH_GAME}/icons/\${res}.png" "\${PATH_ICON}/${GAME_ID}.png"
done

PATH_ICON="${PATH_ICON_BASE}/scalable/apps"
mkdir -p "\${PATH_ICON}"
ln -s "${PATH_GAME}/icons/scalable.svg" "\${PATH_ICON}/${GAME_ID}.svg"
EOF

cat > "$prerm" << EOF
for res in ${APP_MAIN_ICON_RES}; do
	PATH_ICON="${PATH_ICON_BASE}/\${res}/apps"
	rm "\${PATH_ICON}/${GAME_ID}.png"
	rmdir -p --ignore-fail-on-non-empty "\${PATH_ICON}"
done

PATH_ICON="${PATH_ICON_BASE}/scalable/apps"
rm "\${PATH_ICON}/${GAME_ID}.svg"
rmdir -p --ignore-fail-on-non-empty "\${PATH_ICON}"
EOF

write_metadata 'PKG_MAIN'
rm "$postinst" "$prerm"
write_metadata 'PKG_32' 'PKG_64'
build_pkg 'PKG_MAIN' 'PKG_32' 'PKG_64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n32-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_64_PKG"

exit 0
