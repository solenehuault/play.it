# write launcher script - run the game, then clean the user-writable directories
# USAGE: write_bin_run
# CALLS: write_bin_run_dosbox write_bin_run_native write_bin_run_scummvm
# 	write_bin_run_wine
write_bin_run() {
	cat >> "$file" <<- EOF
	# Run the game
	EOF

	case $app_type in
		('dosbox')
			write_bin_run_dosbox
		;;
		('native')
			write_bin_run_native
		;;
		('scummvm')
			write_bin_run_scummvm
		;;
		('wine')
			write_bin_run_wine
		;;
	esac

	if [ $app_type != 'scummvm' ]; then
		cat >> "$file" <<- 'EOF'
		clean_userdir "$PATH_CACHE" "$CACHE_FILES"
		clean_userdir "$PATH_CONFIG" "$CONFIG_FILES"
		clean_userdir "$PATH_DATA" "$DATA_FILES"
		EOF
	fi

	cat >> "$file" <<- EOF
	exit 0
	EOF
}

# write launcher script - run the DOSBox game
# USAGE: write_bin_run_dosbox
# CALLED BY: write_bin_run
write_bin_run_dosbox() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	dosbox -c "mount c .
	c:
	EOF

	if [ "$GAME_IMAGE" ]; then
		case "$GAME_IMAGE_TYPE" in
			('cdrom')
				cat >> "$file" <<- EOF
				mount d $GAME_IMAGE -t cdrom
				EOF
			;;
			('iso'|*)
				cat >> "$file" <<- EOF
				imgmount d $GAME_IMAGE -t iso -fs iso
				EOF
			;;
		esac
	fi

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	$APP_EXE $APP_OPTIONS $@
	exit"
	EOF
}

# write launcher script - run the native game
# USAGE: write_bin_run_native
# CALLED BY: write_bin_run
write_bin_run_native() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	rm --force "$APP_EXE"
	if [ -e "$PATH_DATA/$APP_EXE" ]; then
	  source_dir="$PATH_DATA"
	else
	  source_dir="$PATH_GAME"
	fi
	mkdir --parents "$(dirname $APP_EXE)"
	cp "$source_dir/$APP_EXE" "$APP_EXE"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	"./$APP_EXE" $APP_OPTIONS $@
	EOF
}

# write launcher script - run the ScummVM game
# USAGE: write_bin_run_scummvm
# CALLED BY: write_bin_run
write_bin_run_scummvm() {
	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	scummvm -p "$PATH_GAME" $APP_OPTIONS $@ $SCUMMVM_ID
	EOF
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

