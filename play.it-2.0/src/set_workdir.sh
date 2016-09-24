set_workdir() {
[ $# = 1 ] && PKG="$1"
set_workdir_workdir
while [ $# -ge 1 ]; do
	local pkg=$1
	testvar "$pkg" 'PKG'
	set_workdir_pkg $pkg
	shift 1
done
}

set_workdir_workdir() {
local workdir_name=$(mktemp --dry-run ${GAME_ID_SHORT}.XXXXX)
local archive_size=$(eval echo \$${ARCHIVE}_UNCOMPRESSED_SIZE)
local needed_space=$(($archive_size * 2))
local free_space_tmp=$(df --output=avail /tmp | tail --lines=1)
if [ $free_space_tmp -ge $needed_space ]; then
	export PLAYIT_WORKDIR="/tmp/play.it/${workdir_name}"
else
	[ -w "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="${HOME}/.cache"
	local free_space_cache="$(df --output=avail "$XDG_CACHE_HOME" | tail --lines=1)"
	if [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="${$XDG_CACHE_HOME}/play.it/${workdir_name}"
	else
		export PLAYIT_WORKDIR="${PWD}/play.it/${workdir_name}"
	fi
fi
}

set_workdir_pkg() {
local pkg_id=$(eval echo \$${pkg}_ID)
local pkg_version=$(eval echo \$${pkg}_VERSION)
local pkg_arch=$(eval echo \$${pkg}_ARCH)
local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
export ${pkg}_PATH="$pkg_path"
}

