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
# Botanicula
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170508.1

# Set game-specific variables

GAME_ID='botanicula'
GAME_NAME='Botanicula'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_botanicula_2.0.0.2.sh'
ARCHIVE_GOG_MD5='7b92a379f8d2749e2f97c43ecc540c3c'
ARCHIVE_GOG_SIZE='760000'
ARCHIVE_GOG_VERSION='1.0.1-gog2.0.0.2'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./bin/adl ./runtimes'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./bin/*.xml ./bin/*.swf ./bin/data'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='bin/adl'
APP_MAIN_OPTIONS='bin/BotaniculaLinux-app.xml'
APP_MAIN_ICON_PATH='bin/data/icons'
APP_MAIN_ICON_RES='16 32 36 48 57 72 114 128 256 512'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libnss3, libgtk2.0-0"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID lib32-nss lib32-gtk2"

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
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

cat > "$postinst" << EOF
for res in $APP_MAIN_ICON_RES; do
	PATH_ICON=$PATH_ICON_BASE/\${res}x\${res}/apps
	mkdir --parents "\$PATH_ICON"
	ln --symbolic "$PATH_GAME/$APP_MAIN_ICON_PATH/b\${res}.png" "\$PATH_ICON/$GAME_ID.png"
done
EOF

cat > "$prerm" << EOF
for res in $APP_ICON_RES; do
	PATH_ICON=$PATH_ICON_BASE/\${res}x\${res}/apps
	rm "\$PATH_ICON/$GAME_ID.png"
	rmdir --parents --ignore-fail-on-non-empty "\$PATH_ICON"
done
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
