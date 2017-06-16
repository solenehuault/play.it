# print installation instructions for Debian
# USAGE: print_instructions_deb $pkg[…]
# CALLS: print_instructions_deb_apt print_instructions_deb_dpkg
print_instructions_deb() {
	if [ -e /etc/debian_version ] && cat /etc/debian_version | grep --invert-match '[^0-9.]' 1>/dev/null && [ $(cut -d'.' -f1 /etc/debian_version) -ge 9 ]; then
		print_instructions_deb_apt "$@"
	else
		print_instructions_deb_dpkg "$@"
	fi
}

# print installation instructions for Debian with apt
# USAGE: print_instructions_deb_apt $pkg[…]
# CALLED BY: print_instructions_deb
print_instructions_deb_apt() {
	printf 'apt install'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
}

# print installation instructions for Debian with dpkg + apt-get
# USAGE: print_instructions_deb_dpkg $pkg[…]
# CALLED BY: print_instructions_deb
print_instructions_deb_dpkg() {
	printf 'dpkg -i'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
	printf 'apt-get install -f\n'
}

