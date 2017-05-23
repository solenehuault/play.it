#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
if [ -z $(which fakeroot) ]; then
	echo "fakeroot est introuvable sur votre système."
	echo "Installez-le avant de relancer ce script."
	exit 1
fi
if [ -z $(which md5sum) ]; then
	echo "md5sum est introuvable sur votre système."
	CHECKSUM=none
fi

# Initialisation des variables
ID=star-wars-dark-forces
ID1=$ID
ID2="$ID"_setup
VERSION=1.0
REVISION=1.0.0.9
ARCH=all
PKGDESC="Star Wars: Dark Forces"
PKGDEPS="dosbox"
WRITABLE="DRIVE.CD LOCAL.MSG"
EXE1="DARK.EXE"
EXE2="SETUP.EXE"
DESKNAME="Star Wars: Dark Forces"
ARCHIVE1="gog_star_wars_dark_forces_french_1.0.0.9.deb"
ARCHIVE2="gog_star_wars_dark_forces_1.0.0.9.deb"
MD5SUM1=4d0ddbb3d8aae65321d0aaa988782b71
MD5SUM2=aaf74be99362dd67a4937e9ead961a32

# Définition da la méthode de compression
if [ -z $COMPRESSION ]; then
	COMPRESSION=none
fi
if [ $COMPRESSION = gzip -o $COMPRESSION = xz ]; then
	echo "Utilisation de $COMPRESSION pour la compression du paquet final."
elif [ $COMPRESSION = none ]; then
	echo "Le paquet final ne sera pas compressé."
else
	echo "$COMPRESSION n'est pas une valeur valide pour la variable \$COMPRESSION."
	echo "Les valeurs acceptées sont : none, gzip, xz."
	exit 1
fi
DPKGDEB="fakeroot -- dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ "$1" ]; then
	if [ -f "$ARCHIVE1" ]; then
		ARCHIVE="$ARCHIVE1"
		echo "Utilisation de $(realpath "$ARCHIVE")"
	elif [ -f "$ARCHIVE2" ]; then
		ARCHIVE="$ARCHIVE2"
		echo "Utilisation de $(realpath "$ARCHIVE")"
	else
		echo "Ce script prend en argument l’installeur téléchargé depuis gog.com. ($ARCHIVE)"
		exit 1
	fi
elif [ -f "$1"  ]; then
	ARCHIVE="$1"
else
	echo "$1: fichier introuvable"
	exit 1
fi

# Définition de la méthode de vérification de l’archive
if [ -z $CHECKSUM ]; then
	CHECKSUM=md5sum
fi
if [ $CHECKSUM = none ]; then
	echo "L’intégrité de l’archive ne sera pas vérifiée."
elif [ $CHECKSUM = md5sum ]; then
	echo "L’intégrité de l’archive sera vérifiée par $CHECKSUM."
else
	echo "$CHECKSUM n'est pas une valeur valide pour la variable \$CHECKSUM."
	echo "Les valeurs acceptées sont : none, md5sum."
	exit 1
fi

# Vérification de l’intégrité de l’archive
if [ $CHECKSUM = md5sum ]; then
	echo "Contrôle de l’intégrité de l’archive…"
	ARCHIVESUM=$(md5sum "$ARCHIVE" | cut -d' ' -f1)
	if ! [ "$ARCHIVESUM" = "$MD5SUM1" -o "$ARCHIVESUM" = "$MD5SUM2" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $ARCHIVE n’est pas celui attendu, ou il est corrompu."
		exit 1
	fi
fi

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_$VERSION-gog"$REVISION"_$ARCH
if [ -e $PKGNAME ]; then
	echo "$(realpath $PKGNAME) existe déjà, il peut s’agir d’un résidu d’une utilisation du script avortée."
	echo "Renommez-le ou supprimez-le avant de relancer ce script."
	exit 1
fi
if [ -z "$PREFIX" ]; then
	PREFIX="/usr/local"
fi
echo "\$PREFIX défini à \"$PREFIX\""
if ! [ "$( echo $PREFIX | cut -c1)" = "/" ]; then
	echo "\$PREFIX doit être un chemin absolu."
	exit 1
fi
GAMEPATH="$PREFIX/share/games/$ID"
DOCPATH="$PREFIX/share/doc/$ID"
BINPATH="$PREFIX/games"
DESKPATH="$PREFIX/share/applications"
mkdir -p "$PKGNAME$GAMEPATH" "$PKGNAME$DOCPATH" "$PKGNAME$BINPATH" "$PKGNAME$DESKPATH" $PKGNAME/DEBIAN

# Extraction des données de l’installeur
TMPDIR=$ID.$(date +%s)
dpkg-deb -Rv "$ARCHIVE" $TMPDIR
mv "$TMPDIR/opt/GOG Games"/*/data/* "$PKGNAME$GAMEPATH"
mv "$TMPDIR/opt/GOG Games"/*/docs/*.pdf "$TMPDIR/opt/GOG Games"/*/docs/*.txt "$PKGNAME$DOCPATH"

# Création des lanceurs
echo "#!/bin/sh -e
USERDIR=\"\$HOME/.local/share/games/$ID\"
if ! [ -e \"\$USERDIR/$EXE1\" ]; then
	mkdir -p \"\$USERDIR\"
	cp -surf \"$GAMEPATH\"/* \"\$USERDIR\"
	cd \"\$USERDIR\"
	for writable in $WRITABLE; do
		if [ -h \"\$writable\" ]; then
			cp -a --remove-destination \"$GAMEPATH/\$writable\" \"\$writable\"
		fi
	done

fi
dosbox -c \"mount c \"\$USERDIR\"
c:
\"$EXE1\" \$@
exit\"
exit 0" > "$PKGNAME$BINPATH/$ID1"

echo "#!/bin/sh -e
USERDIR=\"\$HOME/.local/share/games/$ID\"
if ! [ -e \"\$USERDIR/$EXE2\" ]; then
	mkdir -p \"\$USERDIR\"
	cp -surf \"$GAMEPATH\"/* \"\$USERDIR\"
	cd \"\$USERDIR\"
	for writable in $WRITABLE; do
		if [ -h \"\$writable\" ]; then
			cp -a --remove-destination \"$GAMEPATH/\$writable\" \"\$writable\"
		fi
	done
fi
dosbox -c \"mount c \"\$USERDIR\"
c:
\"$EXE2\" \$@
exit\"
exit 0" > "$PKGNAME$BINPATH/$ID2"

chmod 755 "$PKGNAME$BINPATH"/*

# Création des entrées de menu
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=dosbox
Exec=$ID1
Categories=Game;" > "$PKGNAME$DESKPATH/$ID1.desktop"

echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=dosbox
Exec=$ID2
Categories=Settings;" > "$PKGNAME$DESKPATH/$ID2.desktop"

# Création du fichier DEBIAN/control
echo "Package: $ID
Version: $VERSION-gog$REVISION
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
echo "Installez-le en lançant la commande suivante (en root) :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0
