# print installation instructions for Arch Linux
# USAGE: print_instructions_arch $pkg[…]
print_instructions_arch() {
	printf 'pacman -U'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
}

