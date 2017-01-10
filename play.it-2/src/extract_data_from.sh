# extract data from given archive
# USAGE: extract_data $archive[…]
# NEEDED_VARS: $PLAYIT_WORKDIR $ARCHIVE $ARCHIVE_TYPE $ARCHIVE_PASSWD
# CALLS: liberror extract_7z (declared by check_deps_7z)
extract_data_from() {
	for file in "$@"; do
		extract_data_from_print
		local destination="${PLAYIT_WORKDIR}/gamedata"
		mkdir --parents "$destination"
		case "$(eval echo \$${ARCHIVE}_TYPE)" in
			('7z')
				extract_7z "$file" "$destination"
			;;
			('innosetup')
				innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$file"
			;;
			('mojosetup')
				bsdtar --directory "$destination" --extract --file "$file"
				fix_rights "$destination"
			;;
			('mojosetup_unzip')
				unzip -d "$destination" "$file" 1>/dev/null 2>&1 || true
				fix_rights "$destination"
			;;
			('nix_stage1')
				local input_blocksize=$(head --lines=514 "$file" | wc --bytes | tr --delete ' ')
				dd if="$file" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar --extract --file - --directory "$destination"
			;;
			('nix_stage2')
				tar --extract --xz --file "$file" --directory "$destination"
			;;
			('rar')
				if [ -n "$ARCHIVE_PASSWD" ]; then
					UNAR_OPTIONS="-password \"$ARCHIVE_PASSWD\""
				fi
				unar -no-directory -output-directory "$destination" $UNAR_OPTIONS "$file"
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
	done
}

# print data extraction message
# USAGE: extract_data_from_print
# CALLED BY: extract_data_from
extract_data_from_print() {
	local file="$(basename "$file")"
	case ${LANG%_*} in
		('fr')
			printf 'Extraction des données de %s\n' "$file"
		;;
		('en'|*)
			printf 'Extracting data from %s \n' "$file"
		;;
	esac
}

