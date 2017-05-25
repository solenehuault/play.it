# put files from archive in the right package directories
# USAGE: organize_data $id $path
# NEEDED VARS: (PLAYIT_WORKDIR) (PKG) (PKG_PATH)
organize_data() {
	[ $# = 2 ] || return 1
	[ "$PLAYIT_WORKDIR" ] || return 1
	[ $PKG ] || return 1
	[ -n "$(eval echo \$${PKG}_PATH)" ] || return 1

	local archive_path
	if [ -n "$(eval echo \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_path="$(eval echo \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval echo \"\$ARCHIVE_${1}_PATH\")" ]; then
		archive_path="$(eval echo \"\$ARCHIVE_${1}_PATH\")"
	else
		unset archive_path
	fi

	local archive_files
	if [ -n "$(eval echo \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_files="$(eval echo \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval echo \"\$ARCHIVE_${1}_FILES\")" ]; then
		archive_files="$(eval echo \"\$ARCHIVE_${1}_FILES\")"
	else
		unset archive_files
	fi

	if [ "$archive_path" ] && [ "$archive_files" ] && [ -d "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		local pkg_path="$(eval echo \$${PKG}_PATH)${2}"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $archive_files; do
				if [ -e "$file" ]; then
					cp --recursive --force --link --parents "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
}

