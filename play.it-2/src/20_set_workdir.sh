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
# NEEDED VARS: $ARCHIVE $ARCHIVE_SIZE
# CALLED BY: set_workdir
set_workdir_workdir() {
	local workdir_name=$(mktemp --dry-run ${GAME_ID}.XXXXX)
	local needed_space=$(($ARCHIVE_SIZE * 2))
	[ "$XDG_RUNTIME_DIR" ] || XDG_RUNTIME_DIR="/run/user/$(id -u)"
	[ "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="$HOME/.cache"
	local free_space_run=$(df --output=avail "$XDG_RUNTIME_DIR" 2>/dev/null | tail --lines=1)
	local free_space_tmp=$(df --output=avail /tmp 2>/dev/null | tail --lines=1)
	local free_space_cache=$(df --output=avail "$XDG_CACHE_HOME" 2>/dev/null | tail --lines=1)
	if [ $free_space_run -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_RUNTIME_DIR/play.it/$workdir_name"
	elif [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/play.it/$workdir_name"
	elif [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_CACHE_HOME/play.it/$workdir_name"
	else
		export PLAYIT_WORKDIR="$PWD/play.it/$workdir_name"
	fi
	rm --force --recursive "$PLAYIT_WORKDIR"
}

# set package-secific working directory
# USAGE: set_workdir_pkg $pkg
# NEEDED VARS: $PKG_ID $PKG_VERSION $PKG_ARCH $PLAYIT_WORKDIR
# CALLED BY: set_workdir
set_workdir_pkg() {
	local pkg_id
	if [ "$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})" ]; then
		pkg_id="$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})"
	elif [ "$(eval echo \$${1}_ID)" ]; then
		pkg_id="$(eval echo \$${1}_ID)"
	else
		pkg_id="$GAME_ID"
	fi
	eval $(echo export ${1}_ID="$pkg_id")

	local pkg_version="$(eval echo \$${1}_VERSION)"
	if [ ! "$pkg_version" ]; then
		pkg_version="$PKG_VERSION"
	fi
	if [ ! "$pkg_version" ]; then
		pkg_version='1.0-1'
	fi

	local pkg_arch
	set_arch "$1"

	if [ "$PACKAGE_TYPE" = 'arch' ] && [ "$(eval echo \$${1}_ARCH)" = '32' ]; then
		local pkg_path="${PLAYIT_WORKDIR}/lib32-${pkg_id}_${pkg_version}_${pkg_arch}"
	else
		local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
	fi

	export ${1}_PATH="$pkg_path"
}

