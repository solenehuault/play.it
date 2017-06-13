# print installation instructions for Debian
# USAGE: print_instructions_deb $pkg[…]
print_instructions_deb() {
	printf 'dpkg -i'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
	printf 'apt-get install -f\n'
}

