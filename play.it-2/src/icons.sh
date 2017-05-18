# extract .png or .ico files from given file
# USAGE: extract_icon_from $file[…]
# NEEDED VARS: $PLAYIT_WORKDIR
# CALLS: liberror
extract_icon_from() {
	for file in "$@"; do
		local destination="$PLAYIT_WORKDIR/icons"
		mkdir --parents "$destination"
		case ${file##*.} in
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
				liberror 'file_ext' 'extract_icon_from'
			;;
		esac
	done
}

# create icons tree
# USAGE: sort_icons $app
# NEEDED VARS: $app_ID, $app_ICON_RES, PKG, $PKG_PATH, PACKAGE_TYPE
# CALLS: sort_icons_arch, sort_icons_deb, sort_icons_tar
sort_icons() {
for app in $@; do
	testvar "$app" 'APP' || liberror 'app' 'sort_icons'
	local app_id="$(eval echo \$${app}_ID)"
	if [ -z "$app_id" ]; then
		app_id="$GAME_ID"
	fi
	local icon_res="$(eval echo \$${app}_ICON_RES)"
	local pkg_path="$(eval echo \$${PKG}_PATH)"
	case $PACKAGE_TYPE in
		('arch')
			sort_icons_arch
		;;
		('deb')
			sort_icons_deb
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'sort_icons'
		;;
	esac
done
}

# create icons tree for .pkg.tar.xz package
# USAGE: sort_icons_arch
# NEEDED VARS: PATH_ICON_BASE, PLAYIT_WORKDIR
# CALLED BY: sort_icons
sort_icons_arch() {
	for res in $icon_res; do
		path_icon="${PATH_ICON_BASE}/${res}x${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x${res}x*.png; do
			mv "${file}" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
}

# create icons tree for .deb package
# USAGE: sort_icons_deb
# NEEDED VARS: PATH_ICON_BASE, PLAYIT_WORKDIR
# CALLED BY: sort_icons
sort_icons_deb() {
	for res in $icon_res; do
		path_icon="${PATH_ICON_BASE}/${res}x${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x${res}x*.png; do
			mv "${file}" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
}

# extract and sort icons from given .ico or .exe file
# USAGE: extract_and_sort_icons_from $app[…]
# NEEDED VARS: $NO_ICON $PLAYIT_WORKDIR $APP_ID $APP_ICON $APP_ICON_RES $PKG
# 	$PKG_PATH $PACKAGE_TYPE $PATH_GAME
# CALLS: liberror extract_icon_from sort_icons
extract_and_sort_icons_from() {
	local app_icon
	local pkg_path="$(eval echo \$${PKG}_PATH)"
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'sort_icons'
		if [ "$ARCHIVE" ] && [ -n "$(eval echo \$${app}_ICON_${ARCHIVE#ARCHIVE_})" ]; then
			app_icon="$(eval echo \$${app}_ICON_${ARCHIVE#ARCHIVE_})"
			export ${app}_ICON="$app_icon"
		else
			app_icon="$(eval echo \$${app}_ICON)"
		fi
		extract_icon_from "${pkg_path}${PATH_GAME}/$app_icon"
		if [ "${app_icon##*.}" = 'exe' ]; then
			extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		fi
		sort_icons "$app"
		rm --recursive "$PLAYIT_WORKDIR/icons"
	done
}

