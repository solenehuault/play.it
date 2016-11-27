# set working directories
# USAGE: set_workdir $pkg[…]
# CALLS: set_workdir_workdir, testvar, set_workdir_pkg
set_workdir() {
	if [ $# = 1 ]; then
		PKG="$1"
	fi
	set_workdir_workdir
	while [ $# -ge 1 ]; do
		local pkg=$1
		testvar "$pkg" 'PKG'
		set_workdir_pkg $pkg
		shift 1
	done
}

# set gobal working directory
# USAGE: set_workdir_workdir
# NEEDED VARS: GAME_ID_SHORT, ARCHIVE, $ARCHIVE_UNCOMPRESSED_SIZE
# CALLED BY: set_workdir
set_workdir_workdir() {
	local workdir_name=$(mktemp --dry-run ${GAME_ID_SHORT}.XXXXX)
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
# NEEDED VARS: $pkg_ID, $pkg_VERSION, $pkg_ARCH, PLAYIT_WORKDIR
# CALLED BY: set_workdir
set_workdir_pkg() {
	local pkg_id="$(eval echo \$${pkg}_ID)"
	if [ -z "$pkg_id" ]; then
		pkg_id="$GAME_ID"
	fi
	local pkg_version="$(eval echo \$${pkg}_VERSION)"
	if [ -z "$pkg_version" ]; then
		pkg_version='1.0-1'
	fi
	case $PACKAGE_TYPE in
		('arch')
			local pkg_arch="$(eval echo \$${pkg}_ARCH_ARCH)"
		;;
		('deb')
			local pkg_arch="$(eval echo \$${pkg}_ARCH_DEB)"
		;;
		('tar')
			local pkg_arch="$(eval echo \$${pkg}_ARCH_DEB)"
		;;
	esac
	local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
	export ${pkg}_PATH="$pkg_path"
}

