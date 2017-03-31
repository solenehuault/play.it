# write launcher script - set common vars
# USAGE: write_bin_set_vars
write_bin_set_vars() {
	cat >> "$file" <<- EOF
	# Set game-specific variables
	
	GAME_ID="$GAME_ID"
	PATH_GAME="$PATH_GAME"
	
	EOF
	if [ "$app_type" != 'scummvm' ]; then
		cat >> "$file" <<- EOF
		CACHE_DIRS='$CACHE_DIRS'
		CACHE_FILES='$CACHE_FILES'
	
		CONFIG_DIRS='$CONFIG_DIRS'
		CONFIG_FILES='$CONFIG_FILES'
	
		DATA_DIRS='$DATA_DIRS'
		DATA_FILES='$DATA_FILES'
	
		EOF
	else
		cat >> "$file" <<- EOF
		SCUMMVM_ID='$(eval echo \$${app}_SCUMMID)'
	
		EOF
	fi
}

# write launcher script - set target binary/script to run the game
# USAGE: write_bin_set_exe
# CALLED BY: write_bin
write_bin_set_exe() {
	cat >> "$file" <<- EOF
	# Set executable file
	APP_EXE="$app_exe"
	APP_OPTIONS="$app_options"
	export LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"
	
	EOF
}

# write launcher script - set prefix path
# USAGE: write_bin_set_prefix
# CALLS: write_bin_set_prefix_vars, write_bin_set_prefix_funcs
write_bin_set_prefix() {
	cat >> "$file" <<- EOF
	# Set prefix name
	
	if [ -z "\$PREFIX_ID" ]; then
	  PREFIX_ID="$GAME_ID"
	fi
	
	EOF
	write_bin_set_prefix_vars
	write_bin_set_prefix_funcs
}

# write launcher script - set prefix-specific vars
# USAGE: write_bin_set_prefix_vars
# CALLED BY: write_bin_set_prefix
# CALLS: write_bin_set_prefix_wine
write_bin_set_prefix_vars() {
	cat >> "$file" <<- 'EOF'
	# Set prefix-specific variables
	
	if [ ! -w "$XDG_CACHE_HOME" ]; then
	  XDG_CACHE_HOME="$HOME/.cache"
	fi
	if [ ! -w "$XDG_CONFIG_HOME" ]; then
	  XDG_CONFIG_HOME="$HOME/.config"
	fi
	if [ ! -w "$XDG_DATA_HOME" ]; then
	  XDG_DATA_HOME="$HOME/.local/share"
	fi
	
	PATH_CACHE="$XDG_CACHE_HOME/$PREFIX_ID"
	PATH_CONFIG="$XDG_CONFIG_HOME/$PREFIX_ID"
	PATH_DATA="$XDG_DATA_HOME/games/$PREFIX_ID"
	EOF
	if [ "$app_type" = 'wine' ] ; then
		write_bin_set_prefix_vars_wine
	else
		cat >> "$file" <<- 'EOF'
		PATH_PREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
		EOF
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_prefix_vars_wine
# CALLED BY: write_bin_set_prefix_vars
write_bin_set_prefix_vars_wine() {
	cat >> "$file" <<- 'EOF'
	WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"
	WINEARCH='win32'
	WINEDEBUG='-all'
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'
	
	EOF
}

# write launcher script - set prefix-specific functions
# USAGE: write_bin_set_prefix_funcs
# CALLED BY: write_bin_set_prefix
write_bin_set_prefix_funcs() {
	cat >> "$file" <<- 'EOF'
	clean_userdir() {
	  local target="$1"
	  shift 1
	  for file in "$@"; do
	  if [ -f "$file" ] && [ ! -f "$target/$file" ]; then
	    mkdir --parents "$target/${file%/*}"
	    mv "$file" "$target/$file"
	    ln --symbolic "$target/$file" "$file"
	  fi
	  done
	}
	
	init_prefix_dirs() {
	  (
	    cd "$1"
	    shift 1
	    for dir in $@; do
	      rm --force --recursive "$PATH_PREFIX/$dir"
	      mkdir --parents "$PATH_PREFIX/\${dir%/*}"
	      ln --symbolic "$(readlink -e "$dir")" "$PATH_PREFIX/$dir"
	    done
	  )
	}
	
	init_prefix_files() {
	  (
	    cd "$1"
	    find . -type f | while read file; do
	      local file_prefix="$(readlink -e "$PATH_PREFIX/$file")"
	      local file_real="$(readlink -e "$file")"
	      if [ "$file_real" != "$file_prefix" ]; then
	        rm --force "$PATH_PREFIX/$file"
	        mkdir --parents "$PATH_PREFIX/${file%/*}"
	        ln --symbolic "$file_real" "$PATH_PREFIX/$file"
	      fi
	    done
	  )
	}
	
	init_userdir_dirs() {
	  (
	    local dest="$1"
	    shift 1
	    cd "$PATH_GAME"
	    for dir in $@; do
	      if [ -e "$dir" ]; then
	        cp --parents --recursive "$dir" "$dest"
	      else
	        mkdir --parents "$dest/$dir"
	      fi
	    done
	  )
	}
	
	init_userdir_files() {
	  (
	    local dest="$1"
	    shift 1
	    cd "$PATH_GAME"
	    for file in $@; do
	      if [ -e "$file" ]; then
	        cp --parents "$file" "$dest"
	      fi
	    done
	  )
	}
	
	EOF
}

