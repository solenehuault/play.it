# write menu entry
# USAGE: write_desktop $app
# NEEDED VARS: $app_TYPE, $app_ID, $app_NAME, $app_CAT, PKG_PATH, PATH_DESK
# CALLS: liberror
write_desktop() {
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_desktop'
		local type="$(eval echo \$${app}_TYPE)"
		if [ "$winecfg_desktop" != 'done' ] && [ "$type" = 'wine' ]; then
			winecfg_desktop='done'
			write_desktop_winecfg
		fi
		local id="$(eval echo \$${app}_ID)"
		if [ -z "$id" ]; then
			id="$GAME_ID"
		fi
		local name="$(eval echo \$${app}_NAME)"
		if [ -z "$name" ]; then
			name="$GAME_NAME"
		fi
		local cat="$(eval echo \$${app}_CAT)"
		if [ -z "$cat" ]; then
			cat='Game'
		fi
		local target="${PKG_PATH}${PATH_DESK}/${id}.desktop"
		mkdir --parents "${target%/*}"
		cat > "${target}" <<- EOF
		[Desktop Entry]
		Version=1.0
		Type=Application
		Name=$name
		Icon=$id
		Exec=$id
		Categories=$cat
		EOF
	done
}

# write winecfg launcher script
# USAGE: write_desktop_winecfg
# NEEDED VARS: GAME_ID
# CALLS: write_desktop
write_desktop_winecfg() {
	APP_WINECFG_ID="${GAME_ID}_winecfg"
	APP_WINECFG_NAME="$GAME_NAME - WINE configuration"
	APP_WINECFG_CAT='Settings'
	write_desktop 'APP_WINECFG'
	sed --in-place 's/Icon=.\+/Icon=winecfg/' "${PKG_PATH}${PATH_DESK}/${APP_WINECFG_ID}.desktop"
}

