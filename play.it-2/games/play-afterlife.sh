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
# Afterlife
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170329.1

# Set game-specific variables

GAME_ID='afterlife'
GAME_NAME='Afterlife'

ARCHIVE_GOG_EN='gog_afterlife_2.2.0.8.sh'
ARCHIVE_GOG_EN_MD5='3aca0fac1b93adec5aff39d395d995ab'
ARCHIVE_GOG_EN_VERSION='1.1-gog2.2.0.8'
ARCHIVE_GOG_EN_UNCOMPRESSED_SIZE='250000'

ARCHIVE_GOG_FR='gog_afterlife_french_2.2.0.8.sh'
ARCHIVE_GOG_FR_MD5='56b3efee60bc490c68f8040587fc1878'
ARCHIVE_GOG_FR_VERSION='1.1-gog2.2.0.8'
ARCHIVE_GOG_FR_UNCOMPRESSED_SIZE='250000'

ARCHIVE_DOC1_MAIN_PATH='data/noarch/docs'
ARCHIVE_DOC1_MAIN_FILES='./*.pdf'
ARCHIVE_DOC_L10N_PATH='data/noarch/docs'
ARCHIVE_DOC_L10N_FILES='./*.txt'
ARCHIVE_DOC2_MAIN_PATH='data/noarch/data'
ARCHIVE_DOC2_MAIN_FILES='./*.txt'
ARCHIVE_GAME_MAIN_PATH='data/noarch/data'
ARCHIVE_GAME_MAIN_FILES='./*.ini alife/*.ini alife/install.bat alife/dos4gw.exe alife/uvconfig.exe'
ARCHIVE_GAME_L10N_PATH='data/noarch/data'
ARCHIVE_GAME_L10N_FILES='./*'

CONFIG_FILES='./*.ini */*.ini'
DATA_DIRS='./saves'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='alife/afterdos.bat'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256x256'

PKG_L10N_ID="${GAME_ID}-l10n"
PKG_L10N_CONFLICTS_DEB="$PKG_L10N_ID"
PKG_L10N_CONFLICTS_ARCH="$PKG_L10N_ID"
PKG_L10N_PROVIDES_DEB="$PKG_L10N_ID"
PKG_L10N_PROVIDES_ARCH="$PKG_L10N_ID"
PKG_L10N_ID_EN="${GAME_ID}-l10n-en"
PKG_L10N_ID_FR="${GAME_ID}-l10n-fr"
PKG_L10N_DESCRIPTION_EN="English files"
PKG_L10N_DESCRIPTION_FR="French files"

PKG_MAIN_DEPS_DEB="$PKG_L10N_ID, dosbox"
PKG_MAIN_DEPS_ARCH="$PKG_L10N_ID dosbox"

# Load common functions

target_version='2.0'

if [ -z "${PLAYIT_LIB2}" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="${HOME}/.local/share"
	if [ -e "${XDG_DATA_HOME}/play.it/libplayit2.sh" ]; then
		PLAYIT_LIB2="${XDG_DATA_HOME}/play.it/libplayit2.sh"
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
	printf 'target version is: %s\n' "${target_version}"
	return 1
fi

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_GOG_EN' 'ARCHIVE_GOG_FR'
case "$ARCHIVE" in
	('ARCHIVE_GOG_EN')
		PKG_VERSION="$ARCHIVE_GOG_EN_VERSION"
		PKG_L10N_ID="$PKG_L10N_ID_EN"
		PKG_L10N_DESCRIPTION="$PKG_L10N_DESCRIPTION_EN"
	;;
	('ARCHIVE_GOG_FR')
		PKG_VERSION="$ARCHIVE_GOG_FR_VERSION"
		PKG_L10N_ID="$PKG_L10N_ID_FR"
		PKG_L10N_DESCRIPTION="$PKG_L10N_DESCRIPTION_FR"
	;;
esac

check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"
check_deps

# Extract game data

set_workdir 'PKG_MAIN' 'PKG_L10N'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_L10N'
organize_data 'DOC_L10N' "$PATH_DOC"
organize_data 'GAME_L10N' "$PATH_GAME"

PKG='PKG_MAIN'
organize_data 'DOC1_MAIN' "$PATH_DOC"
organize_data 'DOC2_MAIN' "$PATH_DOC"
organize_data 'GAME_MAIN' "$PATH_GAME"

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"

mkdir --parents "$PKG_MAIN_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_MAIN_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "${PLAYIT_WORKDIR}/gamedata"

# Write launchers

write_bin 'APP_MAIN'
sed -i 's|$APP_EXE $APP_OPTIONS $@|cd ${APP_EXE%/*}\n${APP_EXE##*/} $APP_OPTIONS $@|' "${PKG_MAIN_PATH}${PATH_BIN}/${GAME_ID}"
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
write_metadata 'PKG_L10N'
build_pkg 'PKG_L10N' 'PKG_MAIN'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

# Print instructions

print_instructions "$PKG_L10N_PKG" "$PKG_MAIN_PKG"

exit 0
