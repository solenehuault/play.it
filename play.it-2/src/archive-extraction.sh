# extract data from given archive
# USAGE: extract_data_from $archive[…]
# NEEDED_VARS: (ARCHIVE) (ARCHIVE_PASSWD) (ARCHIVE_TYPE) (LANG) (PLAYIT_WORKDIR)
# CALLS: liberror extract_7z extract_data_from_print
extract_data_from() {
	[ "$PLAYIT_WORKDIR" ] || return 1
	[ "$ARCHIVE" ] || return 1

	for file in "$@"; do
		extract_data_from_print "$(basename "$file")"

		local destination="$PLAYIT_WORKDIR/gamedata"
		mkdir --parents "$destination"
		local archive_type="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
		case "$archive_type" in
			('7z')
				extract_7z "$file" "$destination"
			;;
			('debian')
				dpkg-deb --extract "$file" "$destination"
			;;
			('innosetup')
				printf '\n'
				innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$file"
			;;
			('mojosetup')
				bsdtar --directory "$destination" --extract --file "$file"
				set_standard_permissions "$destination"
			;;
			('mojosetup_unzip')
				unzip -o -d "$destination" "$file" 1>/dev/null 2>&1 || true
				set_standard_permissions "$destination"
			;;
			('nix_stage1')
				local input_blocksize=$(head --lines=514 "$file" | wc --bytes | tr --delete ' ')
				dd if="$file" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar --extract --file - --directory "$destination"
			;;
			('nix_stage2')
				tar --extract --xz --file "$file" --directory "$destination"
			;;
			('rar')
				# compute archive password from GOG id
				if [ -z "$ARCHIVE_PASSWD" ] && [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" ]; then
					ARCHIVE_PASSWD="$(printf '%s' "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" | md5sum | cut -d' ' -f1)"
				fi
				if [ -n "$ARCHIVE_PASSWD" ]; then
					UNAR_OPTIONS="-password $ARCHIVE_PASSWD"
				fi
				unar -no-directory -output-directory "$destination" $UNAR_OPTIONS "$file" 1>/dev/null
			;;
			('tar'|'tar.gz')
				tar --extract --file "$file" --directory "$destination"
			;;
			('zip')
				unzip -d "$destination" "$file" 1>/dev/null
			;;
			(*)
				liberror 'ARCHIVE_TYPE' 'extract_data_from'
			;;
		esac

		if [ "$archive_type" != 'innosetup' ]; then
			print_ok
		fi
	done
}

# print data extraction message
# USAGE: extract_data_from_print $file
# NEEDED VARS: (LANG)
# CALLED BY: extract_data_from
extract_data_from_print() {
	case "${LANG%_*}" in
		('fr')
			string='Extraction des données de %s'
		;;
		('en'|*)
			string='Extracting data from %s'
		;;
	esac
	printf "$string" "$1"
}

