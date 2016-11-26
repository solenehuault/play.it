# write menu entry
# USAGE: write_desktop $app
# NEEDED VARS: $app_ID, $app_NAME, $app_CAT, PKG_PATH, PATH_DESK
# CALLS: liberror
write_desktop() {
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_desktop'
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

