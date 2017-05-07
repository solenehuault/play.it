# write winecfg launcher script
# USAGE: write_bin_winecfg
# NEEDED VARS: GAME_ID
# CALLS: write_bin
write_bin_winecfg() {
	if [ "$winecfg_launcher" != '1' ]; then
		winecfg_launcher='1'
		APP_WINECFG_ID="${GAME_ID}_winecfg"
		APP_WINECFG_TYPE='wine'
		APP_WINECFG_EXE='winecfg'
		write_bin 'APP_WINECFG'
		local target="${PKG_PATH}${PATH_BIN}/$APP_WINECFG_ID"
		sed --in-place 's/# Run the game/# Run WINE configuration/' "$target"
		sed --in-place 's/cd "$PATH_PREFIX"//' "$target"
		sed --in-place 's/wine "$APP_EXE" $APP_OPTIONS $@/winecfg/' "$target"
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_wine
# CALLED BY: write_bin_set
write_bin_set_wine() {
	cat >> "$file" <<- 'EOF'
	WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"
	WINEARCH='win32'
	WINEDEBUG='-all'
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

	EOF
}

# write launcher script - set WINE-specific user-writables directories
# USAGE: write_bin_build_wine
# CALLED BY: write_bin_build
write_bin_build_wine() {
	cat >> "$file" <<- 'EOF'
	export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
	if ! [ -e "$WINEPREFIX" ]; then
	  mkdir --parents "$WINEPREFIX"
	  wineboot --init 2>/dev/null
	  rm "$WINEPREFIX/dosdevices/z:"
	fi
	EOF

	if [ "$APP_WINETRICKS" ]; then
		cat >> "$file" <<- EOF
		winetricks $APP_WINETRICKS
		EOF
	fi
}

# write launcher script - run the WINE game
# USAGE: write_bin_run_wine
# CALLED BY: write_bin_run
write_bin_run_wine() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	wine "$APP_EXE" $APP_OPTIONS $@
	EOF
}

