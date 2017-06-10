# extract .png or .ico files from given file
# USAGE: extract_icon_from $file[…]
# NEEDED VARS: PLAYIT_WORKDIR
# CALLS: liberror
extract_icon_from() {
	for file in "$@"; do
		local destination="$PLAYIT_WORKDIR/icons"
		mkdir --parents "$destination"
		case "${file##*.}" in
			('exe')
				if [ "$WRESTOOL_NAME" ]; then
					WRESTOOL_OPTIONS="--name=$WRESTOOL_NAME"
				fi
				wrestool --extract --type=14 $WRESTOOL_OPTIONS --output="$destination" "$file"
			;;
			('ico')
				icotool --extract --output="$destination" "$file" 2>/dev/null
			;;
			('bmp')
				local filename="${file##*/}"
				convert "$file" "$destination/${filename%.bmp}.png"
			;;
			(*)
				liberror 'file extension' 'extract_icon_from'
			;;
		esac
	done
}

# create icons layout
# USAGE: sort_icons $app[…]
# NEEDED VARS: APP_ICON_RES (APP_ID) GAME_ID PKG PKG_PATH
sort_icons() {
for app in $@; do
	testvar "$app" 'APP' || liberror 'app' 'sort_icons'

	local app_id
	if [ -n "$(eval printf -- "%b" "\$${app}_ID")" ]; then
		app_id="$(eval printf -- "%b" "\$${app}_ID")"
	else
		app_id="$GAME_ID"
	fi

	local icon_res="$(eval printf -- "%b" "\$${app}_ICON_RES")"
	local pkg_path="$(eval printf -- "%b" "\$${PKG}_PATH")"
	for res in $icon_res; do
		path_icon="$PATH_ICON_BASE/${res}x${res}/apps"
		mkdir --parents "${pkg_path}${path_icon}"
		for file in "$PLAYIT_WORKDIR"/icons/*${res}x${res}x*.png; do
			mv "$file" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
done
}

# extract and sort icons from given .ico or .exe file
# USAGE: extract_and_sort_icons_from $app[…]
# NEEDED VARS: APP_ICON APP_ICON_RES (APP_ID) GAME_ID PKG PKG_PATH PLAYIT_WORKDIR
# CALLS: extract_icon_from liberror sort_icons
extract_and_sort_icons_from() {
	local app_icon
	local pkg_path="$(eval printf -- "%b" "\$${PKG}_PATH")"
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'sort_icons'

		if [ "$ARCHIVE" ] && [ -n "$(eval printf -- "%b" "\$${app}_ICON_${ARCHIVE#ARCHIVE_}")" ]; then
			app_icon="$(eval printf -- "%b" "\$${app}_ICON_${ARCHIVE#ARCHIVE_}")"
			export ${app}_ICON="$app_icon"
		else
			app_icon="$(eval printf -- "%b" "\$${app}_ICON")"
		fi

		if [ ! "$WRESTOOL_NAME" ] && [ -n "$(eval printf -- "%b" "\$${app}_ICON_ID")" ]; then
			WRESTOOL_NAME="$(eval printf -- "%b" "\$${app}_ICON_ID")"
		fi

		extract_icon_from "${pkg_path}${PATH_GAME}/$app_icon"
		unset WRESTOOL_NAME

		if [ "${app_icon##*.}" = 'exe' ]; then
			extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		fi

		sort_icons "$app"
		rm --recursive "$PLAYIT_WORKDIR/icons"
	done
}

# move icons to the target package
# USAGE: move_icons_to $pkg
# NEEDED VARS: PATH_ICON_BASE PKG
move_icons_to() {
	local source_path="$(eval printf -- "%b" "\$${pkg}_PATH")"
	local destination_path="$(eval printf -- "%b" "\$${1}_PATH")"
	(
		cd "$source_path"
		cp --link --parents --recursive "./$PATH_ICON_BASE" "$destination_path"
		rm --recursive "./$PATH_ICON_BASE"
		rmdir --ignore-fail-on-non-empty --parents "./${PATH_ICON_BASE%/*}"
	)
}

