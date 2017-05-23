#!/bin/sh -e

# Contrôle des dépendances
for dep in innoextract wrestool icotool fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable."
		echo "Installez-le avant de lancer ce script."
		exit 1
	fi
done
if [ -z $(which md5sum) ]; then
	echo "md5sum est introuvable."
	CHECKSUM=none
fi

# Initialisation des variables
ID=star-wars-galactic-battlegrounds
VERSION=1.0
REVISION=2.0.0.2
FULLVERSION=$VERSION-gog$REVISION
ARCH=all
PKGDESC="Star Wars: Galactic Battlegrounds Saga"
PKGDEPS="wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386"
EXE="battlegrounds_x1.exe"
WRITABLE="data/*.dat"
ICON="battlegrounds_x1.exe"
ICONRES=/usr/local/share/icons/hicolor/$iconres/apps
DESKNAME="Star Wars: Galactic Battlegrounds"
ARCHIVE1="setup_sw_galactic_battlegrounds_saga_french_2.0.0.2.exe"
ARCHIVE2="setup_sw_galactic_battlegrounds_saga_2.0.0.2.exe"
MD5SUM1=5822990b353c786def980a1986ba210a
MD5SUM2=154c6526b80b1b80f60fb98bbfe878ce

# Définition du préfixe d'installation
if [ -z "$PREFIX" ]; then
	PREFIX="/usr/local"
fi
echo "\$PREFIX défini à \"$PREFIX\""
if ! [ "$(echo $PREFIX | cut -c1)" = "/" ]; then
	echo "\$PREFIX doit être un chemin absolu."
	exit 1
fi

# Définition de la méthode de compression
if [ -z $COMPRESSION ]; then
	COMPRESSION=none
fi
if [ $COMPRESSION = gzip -o $COMPRESSION = xz ]; then
	echo "Utilisation de $COMPRESSION pour la compression du paquet."
elif [ $COMPRESSION = none ]; then
	echo "Le paquet ne sera pas compressé."
else
	echo "$COMPRESSION n'est pas une valeur valide pour la variable \$COMPRESSION."
	echo "Les valeurs acceptées sont : none, gzip, xz."
	exit 1
fi
DPKGDEB="fakeroot -- dpkg-deb -Z$COMPRESSION -b"

# Définition de la méthode de vérification de l'installeur
if [ -z $CHECKSUM ]; then
	CHECKSUM=md5sum
fi
if [ $CHECKSUM = none ]; then
	echo "L'intégrité de l'installeur ne sera pas vérifiée."
elif [ $CHECKSUM = md5sum ]; then
	echo "L'intégrité de l'installeur sera vérifiée par $CHECKSUM."
else
	echo "$CHECKSUM n'est pas une valeur valide pour la variable \$CHECKSUM."
	echo "Les valeurs acceptées sont : none, md5sum."
	exit 1
fi

# Recherche de la cible
if ! [ "$1" ]; then
	if [ -f "$ARCHIVE1" ]; then
		ARCHIVE="$ARCHIVE1"
		echo "Utilisation de $(realpath $ARCHIVE)"
	elif [ -f "$ARCHIVE2" ]; then
		ARCHIVE="$ARCHIVE2"
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l'installeur téléchargé depuis gog.com. ($ARCHIVE1 ou $ARCHIVE2)"
		exit 1
	fi
elif [ -f "$1" ]; then
	ARCHIVE="$1"
	echo "Utilisation de $(realpath $ARCHIVE)"
else
	echo "$1: fichier introuvable"
	exit 1
fi

# Vérification de l'intégrité de l'installeur
if [ $CHECKSUM = md5sum ]; then
	echo "Contrôle de l'intégrité de l'installeur…"
	ARCHIVESUM=$(md5sum "$ARCHIVE" | cut -d' ' -f1)
	if ! [ "$ARCHIVESUM" = "$MD5SUM1" -o "$ARCHIVESUM" = "$MD5SUM2" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $ARCHIVE n'est pas celui attendu, ou il est corrompu."
		exit 1
	fi
fi

# Préparation de l'arborescence du paquet
PKGNAME="$ID"_"$FULLVERSION"_$ARCH
if [ -e "$PKGNAME" ]; then
	PKGBACKUP=$PKGNAME.$(date +%s)
	echo "$(realpath $PKGNAME) existe déjà."
	mv $PKGNAME $PKGBACKUP
	echo "Il a été renommé en \"$PKGBACKUP\" pour ne pas entraver l'exécution du script."
fi
GAMEPATH="$PREFIX/share/games/$ID"
DOCPATH="$PREFIX/share/doc/$ID"
BINPATH="$PREFIX/games"
DESKPATH="$PREFIX/share/applications"
mkdir -p "$PKGNAME$GAMEPATH" "$PKGNAME$DOCPATH" "$PKGNAME$BINPATH" "$PKGNAME$DESKPATH" $PKGNAME/DEBIAN

# Extraction des données de l'installeur
TMPDIR=$ID.$(date +%s)
innoextract -seL -p -d $TMPDIR "$ARCHIVE"
cp -al $TMPDIR/app/game/* "$PKGNAME$GAMEPATH"
cp -al $TMPDIR/app/*.pdf "$PKGNAME$DOCPATH"

# Écriture du script de lancement
echo "#!/bin/sh -e
USERDIR=\"\$HOME/.local/share/games/$ID\"
if ! [ -e \"\$USERDIR/$EXE\" ]; then
	mkdir -p \"\$USERDIR\"
	cp -surf \"$GAMEPATH\"/* \"\$USERDIR\"
	cd \"\$USERDIR\"
	for writable in $WRITABLE; do
		if [ -h \"\$writable\" ]; then
			cp -a --remove-destination \"$GAMEPATH/\$writable\" \"\$writable\"
		fi
	done
fi
export WINEDEBUG=-all
export WINEPREFIX=\"\$USERDIR/wine-prefix\"
if ! [ -e \"\$WINEPREFIX\" ]; then
	WINEARCH=win32 wineboot -i
	rm \"\$WINEPREFIX/dosdevices/z:\"
	ln -s \"\$USERDIR\" \"\$WINEPREFIX/drive_c\"
fi
cd \"\$WINEPREFIX/drive_c/$ID\"
wine \"$EXE\" \$@
exit 0" > "$PKGNAME$BINPATH/$ID"

chmod 755 "$PKGNAME$BINPATH"/*

# Extraction des icônes
wrestool -t 14 -x "$PKGNAME$GAMEPATH/$EXE" | icotool -x -o $TMPDIR -
for iconres in $ICONRES; do
	ICONPATH="$PREFIX/share/icons/hicolor/$iconres/apps"
	mkdir -p "$PKGNAME$ICONPATH"
	mv $TMPDIR/*_"$iconres"x*.png "$PKGNAME$ICONPATH/$ID.png"
done

# Écriture de l'entrée de menu
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > "$PKGNAME$DESKPATH/$ID.desktop"

# Écriture du fichier DEBIAN/control
echo "Package: $ID
Version: $FULLVERSION
Section: non-free/games
Architecture: $ARCH
Installed-Size: $(du -ks $PKGNAME/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Description: $PKGDESC" > $PKGNAME/DEBIAN/control

# Construction du paquet
rm -rf $TMPDIR
$DPKGDEB $PKGNAME
rm -rf $PKGNAME
echo "Paquet construit."
echo "Installez-le en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0
