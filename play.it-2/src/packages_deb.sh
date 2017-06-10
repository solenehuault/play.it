# write .deb package meta-data
# USAGE: pkg_write_deb
# NEEDED VARS: GAME_NAME PKG_DEPS_DEB
# CALLED BY: write_metadata
pkg_write_deb() {
	local pkg_deps
	if [ "$(eval echo \$${pkg}_DEPS_DEB_${ARCHIVE#ARCHIVE_})" ]; then
		pkg_deps="$(eval echo \$${pkg}_DEPS_DEB_${ARCHIVE#ARCHIVE_})"
	else
		pkg_deps="$(eval echo \$${pkg}_DEPS_DEB)"
	fi
	local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target="$pkg_path/DEBIAN/control"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $pkg_version
	Architecture: $pkg_architecture
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	Section: non-free/games
	EOF

	if [ "$pkg_provide" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_provide
		Provides: $pkg_provide
		Replaces: $pkg_provide
		EOF
	fi

	if [ "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi

	if [ "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		Description: $GAME_NAME - $pkg_description
		 ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		Description: $GAME_NAME
		 ./play.it script version $script_version
		EOF
	fi

	if [ "$pkg_architecture" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi

	if [ -e "$postinst" ]; then
		target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$postinst")

		exit 0
		EOF
		chmod 755 "$target"
	fi

	if [ -e "$prerm" ]; then
		target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$prerm")

		exit 0
		EOF
		chmod 755 "$target"
	fi
}

# build .deb package
# USAGE: pkg_build_deb $pkg_path
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_deb() {
	local pkg_filename="$PWD/${1##*/}.deb"

	local dpkg_options
	case $OPTION_COMPRESSION in
		('gzip'|'none'|'xz')
			dpkg_options="-Z$OPTION_COMPRESSION"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'pkg_build_deb'
		;;
	esac

	pkg_print "${pkg_filename##*/}"
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options --build "$1" "$pkg_filename" 1>/dev/null
	export ${pkg}_PKG="$pkg_filename"
}

