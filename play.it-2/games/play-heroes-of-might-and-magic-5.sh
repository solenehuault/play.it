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
# Heroes of Might and Magic V
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170405.1

# Set game-specific variables

GAME_ID='heroes-of-might-and-magic-5'
GAME_NAME='Heroes of Might and Magic V'

ARCHIVE_GOG_EN='setup_homm5_2.1.0.22.bin'
ARCHIVE_GOG_EN_MD5='9a31aecfcd072f1a01ab4e810f57f894'
ARCHIVE_GOG_EN_TYPE='rar'
ARCHIVE_GOG_EN_SIZE='2500000'
ARCHIVE_GOG_EN_VERSION='2.1-gog2.1.0.22'

ARCHIVE_GOG_FR='setup_homm5_french_2.1.0.22.bin'
ARCHIVE_GOG_FR_MD5='4d56a95f779c9583cdfdc451ca865927'
ARCHIVE_GOG_FR_TYPE='rar'
ARCHIVE_GOG_FR_SIZE='2500000'
ARCHIVE_GOG_FR_VERSION='2.1-gog2.1.0.22'

ARCHIVE_DOC_L10N_PATH='game'
ARCHIVE_DOC_L10N_FILES='./*.txt ./*.pdf ./editor?documentation/homm5_combat_replay.pdf ./editor?documentation/homm5_dialogs_replay.pdf ./editor?documentation/homm5_preset_editor.pdf ./editor?documentation/homm5_spectator_mode.pdf ./editor?documentation/homm5_users_campaign_editor.pdf'

ARCHIVE_DOC_DATA_PATH='game'
ARCHIVE_DOC_DATA_FILES='./editor?documentation'

ARCHIVE_GAME_BIN_PATH='game'
ARCHIVE_GAME_BIN_FILES='./bin ./bina1'

ARCHIVE_GAME_L10N_PATH='game'
ARCHIVE_GAME_L10N_FILES='./dataa1/a1p1-texts.pak ./dataa1/a1-sound.pak ./dataa1/a1-texts.pak ./dataa1/p3-texts.pak ./dataa1/texts.pak ./datals/p5-texts.pak ./datals/p6-texts.pak ./data/p3-texts.pak ./data/sound.pak ./data/texts.pak ./music/cs/death-berein.ogg ./music/cs/death-nico.ogg ./music/cs/heart-griffin.ogg ./music/cs/isabel-trap.ogg ./music/cs/nico-vampire.ogg ./music/cs/ritual-isabel.ogg ./video/intro.ogg ./video/outro.ogg'

ARCHIVE_GAME_DATA_PATH='game'
ARCHIVE_GAME_DATA_FILES='./data ./dataa1 ./datals ./duelpresets ./editor ./hwcursors ./music ./profiles ./splasha1.bmp ./splash.bmp ./video'

DATA_FILES='./*.log'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='bin/h5_game.exe'
APP_MAIN_ICON='bin/h5_game.exe'
APP_MAIN_ICON_RES='16x16 32x32 48x48'

APP_HOF_ID="${GAME_ID}_hof"
APP_HOF_TYPE='wine'
APP_HOF_EXE='bina1/h5_game.exe'
APP_HOF_ICON='bina1/h5_game.exe'
APP_HOF_ICON_RES='16x16 32x32 48x48'
APP_HOF_NAME="$GAME_NAME - Hammers of Fate"

APP_EDIT_ID="${GAME_ID}_edit"
APP_EDIT_TYPE='wine'
APP_EDIT_EXE='bin/h5_mapeditor.exe'
APP_EDIT_ICON='bin/h5_mapeditor.exe'
APP_EDIT_ICON_ID='128'
APP_EDIT_ICON_RES='32x32'
APP_EDIT_NAME="$GAME_NAME - Map Editor"

APP_HOFEDIT_ID="${GAME_ID}_hofedit"
APP_HOFEDIT_TYPE='wine'
APP_HOFEDIT_EXE='bina1/h5_mapeditor.exe'
APP_HOFEDIT_ICON='bina1/h5_mapeditor.exe'
APP_HOFEDIT_ICON_ID='128'
APP_HOFEDIT_ICON_RES='32x32'
APP_HOFEDIT_NAME="$GAME_NAME - Hammers of Fate - Map Editor"

PKG_L10N_ID="${GAME_ID}-l10n"
PKG_L10N_ID_EN="${GAME_ID}-l10n-en"
PKG_L10N_ID_FR="${GAME_ID}-l10n-fr"
PKG_L10N_PROVIDES_DEB="$PKG_L10N_ID"
PKG_L10N_PROVIDES_ARCH="$PKG_L10N_ID"
PKG_L10N_DESCRIPTION_EN='English localization'
PKG_L10N_DESCRIPTION_FR='French localization'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, $PKG_L10N_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID $PKG_L10N_ID wine"

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
case "$ARCHIVE" in
	('ARCHIVE_GOG_EN')
		ARCHIVE_MD5="$ARCHIVE_GOG_EN_MD5"
		ARCHIVE_TYPE="$ARCHIVE_GOG_EN_TYPE"
		ARCHIVE_SIZE="$ARCHIVE_GOG_EN_SIZE"
		ARCHIVE_VERSION="$ARCHIVE_GOG_EN_VERSION"
		PKG_L10N_ID="$PKG_L10N_ID_EN"
		PKG_L10N_DESCRIPTION="$PKG_L10N_DESCRIPTION_EN"
	;;
	('ARCHIVE_GOG_FR')
		ARCHIVE_MD5="$ARCHIVE_GOG_FR_MD5"
		ARCHIVE_TYPE="$ARCHIVE_GOG_FR_TYPE"
		ARCHIVE_SIZE="$ARCHIVE_GOG_FR_SIZE"
		ARCHIVE_VERSION="$ARCHIVE_GOG_FR_VERSION"
		PKG_L10N_ID="$PKG_L10N_ID_FR"
		PKG_L10N_DESCRIPTION="$PKG_L10N_DESCRIPTION_FR"
	;;
esac
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"
check_deps

# Extract game data

set_workdir 'PKG_BIN' 'PKG_L10N' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN'  "$PATH_GAME"

PKG='PKG_L10N'
organize_data 'DOC_L10N'  "$PATH_DOC"
organize_data 'GAME_L10N' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC_DATA'  "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

if [ "$NO_ICON" = '0' ]; then
	(
		cd "${PKG_BIN_PATH}${PATH_GAME}"

		extract_icon_from "$APP_MAIN_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_MAIN'
		rm --recursive "$PLAYIT_WORKDIR/icons"

		extract_icon_from "$APP_HOF_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_HOF'
		rm --recursive "$PLAYIT_WORKDIR/icons"

		WRESTOOL_NAME="$APP_EDIT_ICON_ID"
		extract_icon_from "$APP_EDIT_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_EDIT'
		rm --recursive "$PLAYIT_WORKDIR/icons"

		WRESTOOL_NAME="$APP_HOFEDIT_ICON_ID"
		extract_icon_from "$APP_HOFEDIT_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_HOFEDIT'
		rm --recursive "$PLAYIT_WORKDIR/icons"
	)
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin     'APP_MAIN' 'APP_HOF' 'APP_EDIT' 'APP_HOFEDIT'
write_desktop 'APP_MAIN' 'APP_HOF' 'APP_EDIT' 'APP_HOFEDIT'

(
	cd "${PKG_BIN_PATH}${PATH_BIN}"
	sed -i 's|cd "$PATH_PREFIX"|cd "$PATH_PREFIX/${APP_EXE%/*}"|'                     "$GAME_ID" "$APP_HOF_ID" "$APP_EDIT_ID" "$APP_HOFEDIT_ID"
	sed -i 's|wine "$APP_EXE" $APP_OPTIONS $@|wine "${APP_EXE##*/}" $APP_OPTIONS $@|' "$GAME_ID" "$APP_HOF_ID" "$APP_EDIT_ID" "$APP_HOFEDIT_ID"
)

# Build package

write_metadata 'PKG_BIN' 'PKG_L10N' 'PKG_DATA'
build_pkg      'PKG_BIN' 'PKG_L10N' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_L10N_PKG" "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
