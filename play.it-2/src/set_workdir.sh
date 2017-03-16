# set working directories
# USAGE: set_workdir $pkg[…]
# CALLS: set_workdir_workdir testvar set_workdir_pkg
set_workdir() {
	if [ $# = 1 ]; then
		PKG="$1"
	fi
	set_workdir_workdir
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	export postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export prerm="$PLAYIT_WORKDIR/scripts/prerm"
	while [ $# -ge 1 ]; do
		local pkg=$1
		testvar "$pkg" 'PKG'
		set_workdir_pkg $pkg
		shift 1
	done
}

# set gobal working directory
# USAGE: set_workdir_workdir
# NEEDED VARS: $ARCHIVE $ARCHIVE_UNCOMPRESSED_SIZE
# CALLED BY: set_workdir
set_workdir_workdir() {
	local workdir_name=$(mktemp --dry-run ${GAME_ID}.XXXXX)
	local archive_size=$(eval echo \$${ARCHIVE}_UNCOMPRESSED_SIZE)
	local needed_space=$(($archive_size * 2))
	local free_space_tmp=$(df --output=avail /tmp | tail --lines=1)
	if [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/play.it/${workdir_name}"
	else
		if [ ! -w "$XDG_CACHE_HOME" ]; then
			XDG_CACHE_HOME="${HOME}/.cache"
		fi
		local free_space_cache="$(df --output=avail "$XDG_CACHE_HOME" | tail --lines=1)"
		if [ $free_space_cache -ge $needed_space ]; then
			export PLAYIT_WORKDIR="${XDG_CACHE_HOME}/play.it/${workdir_name}"
		else
			export PLAYIT_WORKDIR="${PWD}/play.it/${workdir_name}"
		fi
	fi
}

# set package-secific working directory
# USAGE: set_workdir_pkg $pkg
# NEEDED VARS: $PKG_ID $PKG_VERSION $PKG_ARCH $PLAYIT_WORKDIR
# CALLED BY: set_workdir
set_workdir_pkg() {
	local pkg_id="$(eval echo \$${pkg}_ID)"
	if [ ! "$pkg_id" ]; then
		pkg_id="$GAME_ID"
	fi

	local pkg_version="$(eval echo \$${pkg}_VERSION)"
	if [ ! "$pkg_version" ]; then
		pkg_version="$PKG_VERSION"
	fi
	if [ ! "$pkg_version" ]; then
		pkg_version='1.0-1'
	fi

	local pkg_arch
	set_arch

	if [ "$PACKAGE_TYPE" = 'arch' ] && [ "$(eval echo \$${pkg}_ARCH)" = '32' ]; then
		local pkg_path="${PLAYIT_WORKDIR}/lib32-${pkg_id}_${pkg_version}_${pkg_arch}"
	else
		local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
	fi

	export ${pkg}_PATH="$pkg_path"
}

