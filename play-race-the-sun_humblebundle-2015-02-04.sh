#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in realpath unzip fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable sur votre système."
		echo "Installez-le avant de relancer ce script."
		exit 1
	fi
done
if [ -z $(which md5sum) ]; then
	echo "md5sum est introuvable sur votre système."
	echo "L’intégrité de l’archive ne sera pas vérifiée."
	CHECKSUM=none
fi

# Initialisation des variables
ID=race-the-sun
VERSION=1.441
REVISION=150204
ARCH=i386
PKGDESC="Race The Sun"
PKGDEPS="libc6, libdrm2, libexpat1, libgcc1, libgl1-mesa-glx, libglapi-mesa, libglu1-mesa, libstdc++6, libx11-6, libx11-xcb1, libxau6, libxcb1, libxcb-dri2-0, libxcb-dri3-0, libxcb-glx0, libxcb-present0, libxcb-sync1, libxcursor1, libxdamage1, libxdmcp6, libxext6, libxfixes3, libxrender1, libxshmfence1, libxxf86vm1"
EXE=RaceTheSun.x86
ICON=RaceTheSun_Data/Resources/UnityPlayer.png
DESKNAME="Race The Sun"
ARCHIVE=RaceTheSunLINUX_1.441.zip
MD5SUM=a7dfaf830e005a024d2d524e9a256331

# Définition de la méthode de compression
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
DPKGDEB="fakeroot dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ "$1" ]; then
	if [ -f $ARCHIVE ]; then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’archive téléchargée depuis humblebundle.com. ($ARCHIVE)"
		exit 1
	fi
elif ! [ -f "$1"  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE="$1"
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
	if [ "$(md5sum "$ARCHIVE" | cut -d' ' -f1)" != "$MD5SUM" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $ARCHIVE n’est pas celui attendu, ou il est corrompu."
		exit 1
	fi
fi

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH
PREFIX=/usr/local
GAMEPATH=$PREFIX/share/games/$ID
BINPATH=$PREFIX/games
DESKPATH=$PREFIX/share/applications
ICONPATH=/usr/local/share/icons/hicolor/128x128/apps
mkdir -p $PKGNAME$GAMEPATH $PKGNAME$BINPATH $PKGNAME$ICONPATH $PKGNAME$DESKPATH $PKGNAME/DEBIAN

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
unzip -d $TMPDIR "$ARCHIVE"
find $TMPDIR/RaceTheSun*/RaceTheSun_Data -type f -execdir chmod 644 {} +
mv $TMPDIR/RaceTheSun*/* $PKGNAME$GAMEPATH

# Création du lanceur
echo "#!/bin/sh -e
cd $GAMEPATH
./$EXE \$@
exit 0" > $PKGNAME$BINPATH/$ID

chmod 755 $PKGNAME$BINPATH/*

# Création de l'entrée de menu
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > $PKGNAME$DESKPATH/$ID.desktop

# Création du fichier DEBIAN/control
echo "Package: $ID
Version: $VERSION-gog$REVISION
Section: non-free/games
Architecture: $ARCH
Installed-Size: $(du -ks $PKGNAME/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Description: $PKGDESC" > $PKGNAME/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/$ICON $ICONPATH/$ID.png
exit 0" > $PKGNAME/DEBIAN/postinst

echo "#!/bin/sh -e
rm $ICONPATH/$ID.png
exit 0" > $PKGNAME/DEBIAN/prerm

chmod 755 $PKGNAME/DEBIAN/postinst $PKGNAME/DEBIAN/prerm

# Construction du paquet
$DPKGDEB $PKGNAME
rm -r $PKGNAME $TMPDIR
echo "Paquet construit."
echo "Installez-le en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0
