# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: (GAME_NAME) (PACKAGE_TYPE) (PACKAGES_LIST)
print_instructions() {
	[ $GAME_NAME ] || return 1
	if [ $# = 0 ]; then
		print_instructions $PACKAGES_LIST
		return 0
	fi
	case "${LANG%_*}" in
		('fr')
			string='\nInstallez %s en lançant la série de commandes suivantes en root :\n'
		;;
		('en'|*)
			string='\nInstall %s by running the following commands as root:\n'
		;;
	esac
	printf "$string" "$GAME_NAME"
	case $PACKAGE_TYPE in
		('arch')
			printf 'pacman -U'
			for pkg in $@; do
				printf ' %s' "$(eval echo ${pkg}_PATH)"
			done
			printf '\n'
		;;
		('deb')
			printf 'dpkg -i'
			for pkg in $@; do
				printf ' %s' "$(eval echo ${pkg}_PATH)"
			done
			printf '\n'
			printf 'apt-get install -f\n'
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'print_instructions'
		;;
	esac
	printf '\n'
}

