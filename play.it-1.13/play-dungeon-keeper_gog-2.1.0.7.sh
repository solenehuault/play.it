#!/bin/sh -e

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
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
# conversion script for the Dungeon Keeper Gold installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

script_version=20160225.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot innoextract realpath'
SCRIPT_DEPS_SOFT='icotool'

GAME_ID='dungeon-keeper'
GAME_ID_SHORT='dk1'
GAME_NAME='Dungeon Keeper'
GAME_NAME_SHORT='DK'

GAME_ARCHIVE1='setup_dungeon_keeper_gold_2.1.0.7.exe'
GAME_ARCHIVE1_MD5='8f8890d743c171fb341c9d9c87c52343'
GAME_ARCHIVE_FULLSIZE='400000'
PKG_REVISION='gog2.1.0.7'

INSTALLER_DOC='app/manual.pdf tmp/gog_eula.txt tmp/eula.txt tmp/eula_de.txt tmp/eula_fr.txt'
INSTALLER_GAME='app/*.exe app/*.ico app/*.ogg app/data app/game.gog app/game.inst app/keeper.cfg app/ldata app/levels app/sound'

GAME_IMAGE='./game.inst'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./keeper.cfg'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./save'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='data/HISCORES.DAT'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

MENU_NAME="${GAME_NAME}"
MENU_NAME_FR="${GAME_NAME}"
MENU_CAT='Games'

APP1_ID="${GAME_ID}"
APP1_EXE='./keeper.exe'
APP1_ICON='./goggame-1207658934.ico'
APP1_ICON_RES='16x16 32x32 48x48 256x256'
APP1_NAME="${GAME_NAME_SHORT} - ${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME_SHORT} - ${GAME_NAME}"

APP2_ID="${GAME_ID}_deeper"
APP2_EXE='./deeper.exe'
APP2_ICON='./gfw_high_addon.ico'
APP2_ICON_RES='16x16 32x32 48x48 256x256'
APP2_NAME="${GAME_NAME_SHORT} - Deeper Dungeons"
APP2_NAME_FR="${GAME_NAME_SHORT} - Deeper Dungeons"

PKG1_ID="${GAME_ID}"
PKG1_ARCH='all'
PKG1_VERSION='1.0'
PKG1_CONFLICTS=''
PKG1_DEPS='dosbox'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

# Load common functions

TARGET_LIB_VERSION='1.13'

if [ -z "${PLAYIT_LIB}" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "${PLAYIT_LIB}" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "${TARGET_LIB_VERSION}"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi

. "${PLAYIT_LIB}"

# Set script-specific functions

help() {
	printf '%s %s' "$0" '[<archive>] [--checksum=md5|none] [--compression=none|gzip|xz] [--prefix=dir] [--lang-txt=en|de|es|fr|it|nl|pl|sv] [--lang-voices=en|de|es|fr|nl|pl|sv]'
	printf '\n\n'
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--checksum=md5|none' "$(l10n 'help_checksum')" "$(l10n 'help_default')" "${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--compression=none|gzip|xz' "$(l10n 'help_compression')" "$(l10n 'help_default')" "${PKG_COMPRESSION_DEFAULT}"
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--prefix=DIR' "$(l10n 'help_prefix')" "$(l10n 'help_default')" "${PKG_PREFIX_DEFAULT}"
	printf '\t%s\n\t%s.\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t(%s: %s)\n\n' '--lang-txt=en|de|es|fr|it|nl|pl|sv' "$(l10n 'help_lang_txt')" "$(l10n 'help_lang_en')" "$(l10n 'help_lang_de')" "$(l10n 'help_lang_es')" "$(l10n 'help_lang_fr')" "$(l10n 'help_lang_it')" "$(l10n 'help_lang_nl')" "$(l10n 'help_lang_pl')" "$(l10n 'help_lang_sv')" "$(l10n 'help_default')" "${GAME_LANG_TXT_DEFAULT}"
	printf '\t%s\n\t%s.\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t(%s: %s)\n\n' '--lang-voices=en|de|es|fr|nl|pl|sv' "$(l10n 'help_lang_voices')" "$(l10n 'help_lang_en')" "$(l10n 'help_lang_de')" "$(l10n 'help_lang_es')" "$(l10n 'help_lang_fr')" "$(l10n 'help_lang_nl')" "$(l10n 'help_lang_pl')" "$(l10n 'help_lang_sv')" "$(l10n 'help_default')" "${GAME_LANG_VOICES_DEFAULT}"
}

set_lang_txt() {
if [ -z "${GAME_LANG_TXT}" ]; then export GAME_LANG_TXT="${GAME_LANG_TXT_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_lang_txt')" "${GAME_LANG_TXT}"
if [ -z "$(printf '#en#de#es#fr#it#nl#pl#sv#' | grep "#${GAME_LANG_TXT}#")" ]; then
	print error
	printf '%s %s --lang-txt.\n' "${GAME_LANG_TXT}" "$(l10n 'value_invalid')"
	printf '%s: en, de, es, fr, it, nl, pl, sv\n' "$(l10n 'value_accepted')"
	printf '%s: %s\n' "$(l10n 'value_default')" "${GAME_LANG_TXT_DEFAULT}"
	printf '\n'
	exit 1
fi
}

set_lang_voices() {
if [ -z "${GAME_LANG_VOICES}" ]; then export GAME_LANG_VOICES="${GAME_LANG_VOICES_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_lang_voices')" "${GAME_LANG_VOICES}"
if [ -z "$(printf '#en#de#es#fr#nl#pl#sv#' | grep "#${GAME_LANG_VOICES}#")" ]; then
	print error
	printf '%s %s --lang-voices.\n' "${GAME_LANG_VOICES}" "$(l10n 'value_invalid')"
	printf '%s: en, de, es, fr, nl, pl, sv\n' "$(l10n 'value_accepted')"
	printf '%s: %s\n' "$(l10n 'value_default')" "${GAME_LANG_VOICES_DEFAULT}"
	printf '\n'
	exit 1
fi
}

# Set extra variables

NO_ICON=0

PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
GAME_LANG_TXT_DEFAULT='en'
GAME_LANG_VOICES_DEFAULT='en'

fetch_args "$@"

set_checksum
set_compression
set_prefix
set_lang_txt
set_lang_voices

if [ "${GAME_LANG_TXT}" != 'en' ] || [ "${GAME_LANG_VOICES}" != 'en' ]; then
	SCRIPT_DEPS_HARD="${SCRIPT_DEPS_HARD} unar"
fi

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'

set_target '1' 'gog.com'

printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}"

print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
fi

rm "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}"
rm "${PKG1_DIR}${PATH_GAME}/${APP2_ICON}"

if [ "${GAME_LANG_TXT}" != 'en' ] || [ "${GAME_LANG_VOICES}" != 'en' ]; then
	extract_data 'unar_passwd' "${PKG1_DIR}${PATH_GAME}/game.gog" "${PKG_TMPDIR}" 'quiet,tolower' ''
fi

if [ "${GAME_LANG_TXT}" != 'en' ]; then
	case "${GAME_LANG_TXT}" in
		de)
			INSTALLER_TXT=keeper/data/german/*
		;;
		es)
			INSTALLER_TXT=keeper/data/spanish/*
		;;
		fr)
			INSTALLER_TXT=keeper/data/french/*
		;;
		it)
			INSTALLER_TXT=keeper/data/italian/*
		;;
		nl)
			INSTALLER_TXT=keeper/data/dutch/*
		;;
		pl)
			INSTALLER_TXT=keeper/data/polish/*
		;;
		sv)
			INSTALLER_TXT=keeper/data/swedish/*
		;;
	esac
	mv "${PKG_TMPDIR}"/${INSTALLER_TXT} "${PKG1_DIR}${PATH_GAME}/data"
fi

if [ "${GAME_LANG_VOICES}" != 'en' ]; then
	case "${GAME_LANG_VOICES}" in
		de)
			INSTALLER_VOICES=keeper/sound/speech/german/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/german/*
		;;
		es)
			INSTALLER_VOICES=keeper/sound/speech/spanish/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/spanish/*
		;;
		fr)
			INSTALLER_VOICES=keeper/sound/speech/french/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/french/*
		;;
		nl)
			INSTALLER_VOICES=keeper/sound/speech/dutch/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/dutch/*
		;;
		pl)
			INSTALLER_VOICES=keeper/sound/speech/polish/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/polish/*
		;;
		sv)
			INSTALLER_VOICES=keeper/sound/speech/swedish/*
			INSTALLER_VOICES_ATLAS=keeper/sound/atlas/swedish/*
		;;
	esac
	mv "${PKG_TMPDIR}"/${INSTALLER_VOICES} "${PKG1_DIR}${PATH_GAME}/sound"
	mv "${PKG_TMPDIR}"/${INSTALLER_VOICES_ATLAS} "${PKG1_DIR}${PATH_GAME}/sound/atlas"
fi

rm -rf "${PKG_TMPDIR}"

print done

# Write launchers

write_bin_dosbox_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"

write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" 'dosbox' "${APP1_ID}" "${APP2_ID}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' 'dosbox'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' 'dosbox'

printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"

printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
