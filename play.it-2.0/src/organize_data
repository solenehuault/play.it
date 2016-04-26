organize_data() {
[ -n "$PKG_PATH" ] || PKG_PATH="$(eval echo \$${PKG}_PATH)"
if [ -n "${ARCHIVE_DOC_PATH}" ]; then
	organize_data_doc
fi
if [ -n "${ARCHIVE_GAME_PATH}" ]; then
	organize_data_game
fi
}

organize_data_doc() {
mkdir --parents "${PKG_PATH}${PATH_DOC}"
cd "${PLAYIT_WORKDIR}/gamedata/${ARCHIVE_DOC_PATH}"
for file in $ARCHIVE_DOC_FILES; do
	mv "$file" "${PKG_PATH}${PATH_DOC}"
done
cd - 1>/dev/null
}

organize_data_game() {
mkdir --parents "${PKG_PATH}${PATH_GAME}"
cd "${PLAYIT_WORKDIR}/gamedata/${ARCHIVE_GAME_PATH}"
for file in $ARCHIVE_GAME_FILES; do
	mv "$file" "${PKG_PATH}${PATH_GAME}"
done
cd - 1>/dev/null
}

