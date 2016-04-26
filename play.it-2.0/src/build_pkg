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

build_pkg_deb() {
local pkg_filename="${PWD}/${pkg_path##*/}.deb"
build_pkg_print
TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb -Z$COMPRESSION_METHOD -b "$pkg_path" "$pkg_filename" 1>/dev/null
}

build_pkg_tar() {
local pkg_filename="${PWD}/${pkg_path##*/}.tar"
build_pkg_print
cd "$pkg_path"
tar --create --file "$pkg_filename" .
cd -
}

build_pkg_print() {
case ${LANG%_*} in
	fr) echo "Construction de $pkg_filename" ;;
	en|*) echo "Building $pkg_filename" ;;
esac
}

