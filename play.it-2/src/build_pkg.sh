# build .pkg.tar package, .deb package or .tar archive
# USAGE: build_pkg $pkg[…]
# NEEDED VARS: $pkg_PATH, PACKAGE_TYPE
# CALLS: testvar, liberror, build_pkg_arch, build_pkg_deb, build_pkg_tar
build_pkg() {
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		case $PACKAGE_TYPE in
			('arch')
				build_pkg_arch
			;;
			('deb')
				build_pkg_deb
			;;
			('tar')
				build_pkg_tar
			;;
			(*)
				liberror 'PACKAGE_TYPE' 'build_pkg'
			;;
		esac
	done
}

# build .pkg.tar package
# USAGE: build_pkg_arch
# NEEDED VARS: PLAYIT_WORKDIR, COMPRESSION_METHOD
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_arch() {
	local pkg_filename="${PWD}/${pkg_path##*/}.pkg.tar"
	local tar_options='--create'
	case $COMPRESSION_METHOD in
		('gzip')
			tar_options="$tar_options --gzip"
			pkg_filename="${pkg_filename}.gz"
		;;
		('xz')
			tar_options="$tar_options --xz"
			pkg_filename="${pkg_filename}.xz"
		;;
		('none') ;;
		(*)
			liberror 'PACKAGE_TYPE' 'build_pkg'
		;;
	esac
	build_pkg_print
	cd "$pkg_path"
	tar $tar_options --file "$pkg_filename" .PKGINFO *
	cd - > /dev/null
}

# build .deb package
# USAGE: build_pkg_deb
# NEEDED VARS: PLAYIT_WORKDIR, COMPRESSION_METHOD
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_deb() {
	local pkg_filename="${PWD}/${pkg_path##*/}.deb"
	local dpkg_options="-Z$COMPRESSION_METHOD --build \"$pkg_path\""
	build_pkg_print
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options "$pkg_filename" 1>/dev/null
}

# build .tar archive
# USAGE: build_pkg_tar
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_tar() {
	local pkg_filename="${PWD}/${pkg_path##*/}.tar"
	local tar_options='--create'
	case $COMPRESSION_METHOD in
		('gzip')
			tar_options="$tar_options --gzip"
			pkg_filename="${pkg_filename}.gz"
		;;
		('xz')
			tar_options="$tar_options --xz"
			pkg_filename="${pkg_filename}.xz"
		;;
		('none') ;;
		(*)
			liberror 'PACKAGE_TYPE' 'build_pkg'
		;;
	esac
	build_pkg_print
	cd "$pkg_path"
	tar $tar_options --file "$pkg_filename" .
	cd - > /dev/null
}

# print package building message
# USAGE: build_pkg_print
# CALLED BY: build_pkg_deb, build_pkg_tar
build_pkg_print() {
	case ${LANG%_*} in
		('fr')
			printf 'Construction de %s\n' "$pkg_filename"
		;;
		('en'|*)
			printf 'Building %s\n' "$pkg_filename"
		;;
	esac
}

