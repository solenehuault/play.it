# build .deb package or .tar archive
# USAGE: build_pkg $pkg
# NEEDED VARS: $pkg_PATH, PACKAGE_TYPE
# CALLS: testvar, liberror, build_pkg_deb, build_pkg_tar
build_pkg() {
local pkg=$1
testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
local pkg_path="$(eval echo \$${pkg}_PATH)"
case $PACKAGE_TYPE in
	deb) build_pkg_deb ;;
	tar) build_pkg_tar ;;
	*) liberror 'PACKAGE_TYPE' 'build_pkg'
esac
}

# build .deb package
# USAGE: build_pkg_deb
# NEEDED VARS: PLAYIT_WORKDIR, COMPRESSION_METHOD
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_deb() {
local pkg_filename="${PWD}/${pkg_path##*/}.deb"
build_pkg_print
TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb -Z$COMPRESSION_METHOD -b "$pkg_path" "$pkg_filename" 1>/dev/null
}

# build .tar archive
# USAGE: build_pkg_tar
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_tar() {
local pkg_filename="${PWD}/${pkg_path##*/}.tar"
build_pkg_print
cd "$pkg_path"
tar --create --file "$pkg_filename" .
cd - > /dev/null
}

# print package building message
# USAGE: build_pkg_print
# CALLED BY: build_pkg_deb, build_pkg_tar
build_pkg_print() {
case ${LANG%_*} in
	fr) echo "Construction de $pkg_filename" ;;
	en|*) echo "Building $pkg_filename" ;;
esac
}

