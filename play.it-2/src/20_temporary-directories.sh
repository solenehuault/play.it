# set temporary directories
# USAGE: set_temp_directories $pkg[…]
# NEEDED VARS: (ARCHIVE_SIZE) GAME_ID (LANG) (PWD) (XDG_CACHE_HOME) (XDG_RUNTIME_DIR)
# CALLS: set_temp_directories_error_no_size set_temp_directories_error_not_enough_space set_temp_directories_pkg testvar
set_temp_directories() {

	# If $PLAYIT_WORKDIR is already set, delete it before setting a new one
	[ "$PLAYIT_WORKDIR" ] && rm --force --recursive "$PLAYIT_WORKDIR"

	# If there is only a single package, make it the default one for the current instance
	[ $# = 1 ] && PKG="$1"

	# Generate an unique name for the current instance
	local name="play.it/$(mktemp --dry-run ${GAME_ID}.XXXXX)"

	# Look for a directory with enough free space to work in
	if [ "$ARCHIVE_SIZE" ]; then
		local needed_space=$(($ARCHIVE_SIZE * 2))
	else
		set_temp_directories_error_no_size
	fi
	[ "$XDG_RUNTIME_DIR" ] || XDG_RUNTIME_DIR="/run/user/$(id -u)"
	[ "$XDG_CACHE_HOME" ]  || XDG_CACHE_HOME="$HOME/.cache"
	local free_space_run=$(df --output=avail "$XDG_RUNTIME_DIR" 2>/dev/null | tail --lines=1)
	local free_space_tmp=$(df --output=avail /tmp 2>/dev/null | tail --lines=1)
	local free_space_cache=$(df --output=avail "$XDG_CACHE_HOME" 2>/dev/null | tail --lines=1)
	local free_space_pwd=$(df --output=avail "$PWD" 2>/dev/null | tail --lines=1)
	if [ -w "$XDG_RUNTIME_DIR" ] && [ $free_space_run -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_RUNTIME_DIR/$name"
	elif [ -w '/tmp' ] && [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/$name"
	elif [ -w "$XDG_CACHE_HOME" ] && [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_CACHE_HOME/$name"
	elif [ -w "$PWD" ] && [ $free_space_pwd -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$PWD/$name"
	else
		set_temp_directories_error_not_enough_space
	fi

	# If $PLAYIT_WORKDIR is an already existing directory, set a new one
	if [ -e "$PLAYIT_WORKDIR" ]; then
		set_temp_directories
		return 0
	fi

	# Set $postinst and $prerm
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	export postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export prerm="$PLAYIT_WORKDIR/scripts/prerm"

	# Set temporary directories for each package to build
	for pkg in "$@"; do
		testvar "$pkg" 'PKG'
		set_temp_directories_pkg $pkg
	done
}

# set package-secific temporary directory
# USAGE: set_temp_directories_pkg $pkg
# NEEDED VARS: (ARCHIVE) (PACKAGE_TYPE) PLAYIT_WORKDIR (PKG_ARCH) PKG_ID|GAME_ID PKG_VERSION|script_version
# CALLED BY: set_temp_directories
set_temp_directories_pkg() {

	# Get package ID
	local pkg_id
	if [ "$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})" ]; then
		pkg_id="$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})"
	elif [ "$(eval echo \$${1}_ID)" ]; then
		pkg_id="$(eval echo \$${1}_ID)"
	else
		pkg_id="$GAME_ID"
	fi
	export ${1}_ID="$pkg_id"

	# Get package version
	local pkg_version
	if [ -n "$(eval echo \$${1}_VERSION)" ]; then
		pkg_version="$(eval echo \$${1}_VERSION)+$script_version"
	elif [ "$PKG_VERSION" ]; then
		pkg_version="$PKG_VERSION"
	else
		pkg_version='1.0-1+$script_version'
	fi

	# Get package architecture
	local pkg_architecture
	set_architecture "$1"

	# Set $PKG_PATH
	if [ "$PACKAGE_TYPE" = 'arch' ] && [ "$(eval echo \$${1}_ARCH)" = '32' ]; then
		pkg_id="lib32-$pkg_id"
	fi
	export ${1}_PATH="$PLAYIT_WORKDIR/${pkg_id}_${pkg_version}_${pkg_architecture}"
}

# display an error if set_temp_directories() is called before setting $ARCHIVE_SIZE
# USAGE: set_temp_directories_error_no_size
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_no_size() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='$ARCHIVE_SIZE doit être défini avant tout appel à set_temp_directories().\n'
		;;
		('en'|*)
			string='$ARCHIVE_SIZE must be set before any call to set_temp_directories().\n'
		;;
	esac
	printf "$string"
	return 1
}

# display an error if there is not enough free space to work in any of the tested directories
# USAGE: set_temp_directories_error_not_enough_space
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_not_enough_space() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Il n’y a pas assez d’espace libre dans les différents répertoires testés :\n'
		;;
		('en'|*)
			string='There is not enough free space in the tested directories:\n'
		;;
	esac
	printf "$string"
	for path in "$XDG_RUNTIME_DIR" '/tmp' "$XDG_CACHE_HOME" "$PWD"; do
		printf '%s\n' "$path"
	done
	return 1
}

