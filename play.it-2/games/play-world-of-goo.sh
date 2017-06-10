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

script_version=20170610.1

# Set game-specific variables

SCRIPT_DEPS='find'

GAME_ID='world-of-goo'
GAME_NAME='World of Goo'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_world_of_goo_2.0.0.3.sh'
ARCHIVE_GOG_MD5='5359b8e7e9289fba4bcf74cf22856655'
ARCHIVE_GOG_SIZE='82000'
ARCHIVE_GOG_VERSION='1.41-gog2.0.0.3'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game'
ARCHIVE_DOC2_FILES='./*.html ./*.txt'

ARCHIVE_GAME_BIN32_PATH='data/noarch/game'
ARCHIVE_GAME_BIN32_FILES='./WorldOfGoo.bin32 ./libs32'

ARCHIVE_GAME_BIN64_PATH='data/noarch/game'
ARCHIVE_GAME_BIN64_FILES='./WorldOfGoo.bin64 ./libs64'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./icons ./properties ./res'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='WorldOfGoo.bin32'
APP_MAIN_EXE_BIN64='WorldOfGoo.bin64'
APP_MAIN_ICON_RES='16 22 32 48 64 128'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libglu1-mesa | libglu1, libogg0, libsdl1.2debian, libsdl-mixer1.2"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-libogg lib32-sdl lib32-sdl_mixer"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glu libogg sdl sdl_mixer"

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

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"
(
	cd "$PLAYIT_WORKDIR/gamedata/$ARCHIVE_GAME_BIN32_PATH"
	find res -name '*.binltl' | while read file; do
		cp --parents "$file" "${PKG_BIN32_PATH}${PATH_GAME}"
		rm "$file"
	done
)

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"
(
	cd "$PLAYIT_WORKDIR/gamedata/$ARCHIVE_GAME_BIN64_PATH"
	find res -name '*.binltl64' | while read file; do
		cp --parents "$file" "${PKG_BIN64_PATH}${PATH_GAME}"
		rm "$file"
	done
)

PKG='PKG_DATA'
find "$PLAYIT_WORKDIR/gamedata/$ARCHIVE_GAME_DATA_PATH/res" -type d -empty -delete
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

cat > "$postinst" << EOF
for res in ${APP_MAIN_ICON_RES}; do
	PATH_ICON="${PATH_ICON_BASE}/\${res}x\${res}/apps"
	mkdir -p "\${PATH_ICON}"
	ln -s "${PATH_GAME}/icons/\${res}x\${res}.png" "\${PATH_ICON}/${GAME_ID}.png"
done
PATH_ICON="${PATH_ICON_BASE}/scalable/apps"
mkdir -p "\${PATH_ICON}"
ln -s "${PATH_GAME}/icons/scalable.svg" "\${PATH_ICON}/${GAME_ID}.svg"
EOF

cat > "$prerm" << EOF
for res in ${APP_MAIN_ICON_RES}; do
	PATH_ICON="${PATH_ICON_BASE}/\${res}x\${res}/apps"
	rm "\${PATH_ICON}/${GAME_ID}.png"
	rmdir -p --ignore-fail-on-non-empty "\${PATH_ICON}"
done
PATH_ICON="${PATH_ICON_BASE}/scalable/apps"
rm "\${PATH_ICON}/${GAME_ID}.svg"
rmdir -p --ignore-fail-on-non-empty "\${PATH_ICON}"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN32' 'PKG_BIN64'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN32'
printf '64-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN64'

exit 0
