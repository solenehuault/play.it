#!/bin/sh
set -e

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
# conversion script for the Startopia installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161015.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='startopia'
GAME_ID_SHORT='stopia'
GAME_NAME='StarTopia'

GAME_ARCHIVE1='setup_startopia_2.0.0.17.exe'
GAME_ARCHIVE1_MD5='4fe8d194afc1012e136ed3e82f1de171'
GAME_ARCHIVE_FULLSIZE='600000'
ARCHIVE_TYPE='inno'
PKG_REVISION='gog2.0.0.17'

TRADFR_ARCHIVE1='startopiafr-txt.7z'
TRADFR_ARCHIVE1_MD5='a1502d87d5ab3f9bc5a232acac99ee63'
TRADFR_ARCHIVE2='startopiafr-snd.7z'
TRADFR_ARCHIVE2_MD5='c403ff9bcb4ebeda4abb44e89639c7ca'
TRADFR_ARCHIVE_TYPE='7z'

INSTALLER_PATH='app'
INSTALLER_JUNK='./gameuxinstallhelper.dll ./gfw_high.ico ./goggame.dll ./gog.ico ./support.ico'
INSTALLER_DOC='./eula ./weblinks ./*.html ./*.pdf ./*.rtf ./*.txt ../tmp/*eula.txt'
INSTALLER_GAME_PKG1='./*.dll ./*.exe'
INSTALLER_GAME_PKG2='./*'
INSTALLER_GAME_PKG3='data/speech/english'
INSTALLER_GAME_PKG4='data/speech/french'
INSTALLER_GAME_PKG5='languageinis/startopiaeng.ini text/english'
INSTALLER_GAME_PKG6='languageinis/startopiafre.ini text/french'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./profiles'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='./*.txt'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./startopia.exe'
APP1_ICON='./startopia.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_VERSION='1.01b'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - common data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID}, ${PKG1_DEPS}"

PKG3_ID="${GAME_ID}-l10n-en-speech"
PKG3_VERSION="${PKG_VERSION}"
PKG3_ARCH='all'
PKG3_CONFLICTS=''
PKG3_DEPS="${PKG2_ID}"
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} - English speech
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG4_ID="${GAME_ID}-l10n-fr-speech"
PKG4_VERSION="${PKG_VERSION}"
PKG4_ARCH='all'
PKG4_CONFLICTS=''
PKG4_DEPS="${PKG2_ID}"
PKG4_RECS=''
PKG4_DESC="${GAME_NAME} - French speech
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG3_ID} | ${PKG4_ID}, ${PKG1_DEPS}"

PKG5_ID="${GAME_ID}-l10n-en-text"
PKG5_VERSION="${PKG_VERSION}"
PKG5_ARCH='all'
PKG5_CONFLICTS=''
PKG5_DEPS="${PKG2_ID}"
PKG5_RECS=''
PKG5_DESC="${GAME_NAME} - English text
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG6_ID="${GAME_ID}-l10n-fr-text"
PKG6_VERSION="${PKG_VERSION}"
PKG6_ARCH='all'
PKG6_CONFLICTS=''
PKG6_DEPS="${PKG2_ID}"
PKG6_RECS=''
PKG6_DESC="${GAME_NAME} - French text
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG5_ID} | ${PKG6_ID}, ${PKG1_DEPS}"

# Load common functions

TARGET_LIB_VERSION='1.14'

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

# Set extra variables

NO_ICON='0'

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

printf '\n'
set_target '1' 'gog.com'
set_target_optional 'TRADFR_TXT_ARCHIVE' "${TRADFR_ARCHIVE1}"
set_target_optional 'TRADFR_SND_ARCHIVE' "${TRADFR_ARCHIVE2}"
[ -n "${TRADFR_TXT_ARCHIVE}" ] || [ -n "${TRADFR_SND_ARCHIVE}" ] && SCRIPT_DEPS_HARD="7z ${SCRIPT_DEPS_HARD}"
printf '\n'

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
[ -n "${TRADFR_SND_ARCHIVE}" ] && game_mkdir 'PKG4_DIR' "${PKG4_ID}_${PKG4_VERSION}-${PKG_REVISION}_${PKG4_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG5_DIR' "${PKG5_ID}_${PKG5_VERSION}-${PKG_REVISION}_${PKG5_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
[ -n "${TRADFR_TXT_ARCHIVE}" ] && game_mkdir 'PKG6_DIR' "${PKG6_ID}_${PKG6_VERSION}-${PKG_REVISION}_${PKG6_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"
	[ -n "${TRADFR_TXT_ARCHIVE}" ] && checksum "${TRADFR_TXT_ARCHIVE}" 'quiet' "${TRADFR_ARCHIVE1_MD5}"
	[ -n "${TRADFR_SND_ARCHIVE}" ] && checksum "${TRADFR_SND_ARCHIVE}" 'quiet' "${TRADFR_ARCHIVE2_MD5}"
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"
for pkg_dir in "${PKG2_DIR}" "${PKG3_DIR}" "${PKG5_DIR}"; do
	rm -Rf "${pkg_dir}"
	mkdir -p "${pkg_dir}/DEBIAN" "${pkg_dir}/${PATH_GAME}"
done
[ -n "${TRADFR_TXT_ARCHIVE}" ] && rm -Rf "${PKG4_DIR}" && mkdir -p "${PKG4_DIR}/DEBIAN" "${PKG4_DIR}/${PATH_GAME}"
[ -n "${TRADFR_SND_ARCHIVE}" ] && rm -Rf "${PKG6_DIR}" && mkdir -p "${PKG6_DIR}/DEBIAN" "${PKG6_DIR}/${PATH_GAME}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
[ -n "${TRADFR_TXT_ARCHIVE}" ] && extract_data "${TRADFR_ARCHIVE_TYPE}" "${TRADFR_TXT_ARCHIVE}" "${PKG_TMPDIR}/app" 'quiet'
[ -n "${TRADFR_SND_ARCHIVE}" ] && extract_data "${TRADFR_ARCHIVE_TYPE}" "${TRADFR_SND_ARCHIVE}" "${PKG_TMPDIR}/app" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG3}; do
	mkdir -p "${PKG3_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG3_DIR}${PATH_GAME}/${file}"
done

if [ -n "${TRADFR_SND_ARCHIVE}" ]; then
for file in ${INSTALLER_GAME_PKG4}; do
	mkdir -p "${PKG4_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG4_DIR}${PATH_GAME}/${file}"
done
fi

rm -rf 'data/speech'

for file in ${INSTALLER_GAME_PKG5}; do
	mkdir -p "${PKG5_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG5_DIR}${PATH_GAME}/${file}"
done

if [ -n "${TRADFR_TXT_ARCHIVE}" ]; then
for file in ${INSTALLER_GAME_PKG6}; do
	mkdir -p "${PKG6_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG6_DIR}${PATH_GAME}/${file}"
done
fi

rm -rf 'languageinis' 'text'

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done
cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi

sed -i 's/IntroPath=.\+/IntroPath="intro\\"/' "${PKG2_DIR}${PATH_GAME}/startopia.ini"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"
postinst="${PKG3_DIR}/DEBIAN/postinst"
cat > "${postinst}" << EOF
#!/bin/sh -e
sed -i 's/TextLanguage=.\+/TextLanguage=English/' ${PATH_GAME}/startopia.ini
exit 0
EOF
chmod 755 "${postinst}"

if [ -n "${TRADFR_SND_ARCHIVE}" ]; then
	write_pkg_debian "${PKG4_DIR}" "${PKG4_ID}" "${PKG4_VERSION}-${PKG_REVISION}" "${PKG4_ARCH}" "${PKG4_CONFLICTS}" "${PKG4_DEPS}" "${PKG4_RECS}" "${PKG4_DESC}"
	postinst="${PKG4_DIR}/DEBIAN/postinst"
	cat > "${postinst}" <<- EOF
	#!/bin/sh -e
	sed -i 's/TextLanguage=.\+/TextLanguage=French/' ${PATH_GAME}/startopia.ini
	exit 0
	EOF
	chmod 755 "${postinst}"
fi

write_pkg_debian "${PKG5_DIR}" "${PKG5_ID}" "${PKG5_VERSION}-${PKG_REVISION}" "${PKG5_ARCH}" "${PKG5_CONFLICTS}" "${PKG5_DEPS}" "${PKG5_RECS}" "${PKG5_DESC}"
postinst="${PKG5_DIR}/DEBIAN/postinst"
cat > "${postinst}" << EOF
#!/bin/sh -e
sed -i 's/SpeechLanguage=.\+/SpeechLanguage=English/' ${PATH_GAME}/startopia.ini
exit 0
EOF
chmod 755 "${postinst}"

if [ -n "${TRADFR_TXT_ARCHIVE}" ]; then
	write_pkg_debian "${PKG6_DIR}" "${PKG6_ID}" "${PKG6_VERSION}-${PKG_REVISION}" "${PKG6_ARCH}" "${PKG6_CONFLICTS}" "${PKG6_DEPS}" "${PKG6_RECS}" "${PKG6_DESC}"
	postinst="${PKG6_DIR}/DEBIAN/postinst"
	cat > "${postinst}" <<- EOF
	#!/bin/sh -e
	sed -i 's/SpeechLanguage=.\+/SpeechLanguage=French/' ${PATH_GAME}/startopia.ini
	exit 0
	EOF
	chmod 755 "${postinst}"
fi

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
[ -n "${TRADFR_SND_ARCHIVE}" ] && build_pkg "${PKG4_DIR}" "${PKG4_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG5_DIR}" "${PKG5_DESC}" "${PKG_COMPRESSION}" 'quiet'
[ -n "${TRADFR_TXT_ARCHIVE}" ] && build_pkg "${PKG6_DIR}" "${PKG6_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

if [ -n "${TRADFR_TXT_ARCHIVE}" ] && [ -n "${TRADFR_SND_ARCHIVE}" ]; then
	print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG4_DIR}" "${PKG6_DIR}" "${PKG1_DIR}"
elif [ -n "${TRADFR_SND_ARCHIVE}" ]; then
	print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG4_DIR}" "${PKG5_DIR}" "${PKG1_DIR}"
elif [ -n "${TRADFR_TXT_ARCHIVE}" ]; then
	print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG3_DIR}" "${PKG6_DIR}" "${PKG1_DIR}"
else
	print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG3_DIR}" "${PKG5_DIR}" "${PKG1_DIR}"
fi

printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
