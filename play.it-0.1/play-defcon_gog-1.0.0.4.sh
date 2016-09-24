#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in realpath fakeroot; do
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
ID=defcon
VERSION=1.6
REVISION=1.0.0.4
ARCH1=i386
ARCH2=amd64
PKGDESC="DEFCON"
PKGDEPS="libc6, libdrm2, libexpat1, libgcc1, libgl1-mesa-glx, libglapi-mesa, libstdc++6, libvorbisfile3, libx11-6, libx11-xcb1, libxau6, libxcb1, libxcb-dri2-0, libxcb-dri3-0, libxcb-glx0, libxcb-present0, libxcb-sync1, libxdamage1, libxdmcp6, libxext6, libxfixes3, libxshmfence1, libxxf86vm1"
EXE1=defcon.bin.x86
EXE2=defcon.bin.x86_64
DESKNAME="DEFCON"
ARCHIVE=defcon_1.0.0.4.tar.gz
MD5SUM=4e45537264fa7961f20b57e49049c4ea

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ $1 ]; then
	if [ -f $ARCHIVE ]; then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’installeur téléchargé depuis gog.com. (version $REVISION)"
		exit 1
	fi
elif ! [ -f $1  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE=$1
fi

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

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
mkdir $TMPDIR
tar xvf "$ARCHIVE" -C $TMPDIR

# Préparation de l’arborescence du paquet
PKGNAME1="$ID"_$VERSION-gog"$REVISION"_$ARCH1
PKGNAME2="$ID"_$VERSION-gog"$REVISION"_$ARCH2
PREFIX=/usr/local
GAMEPATH=$PREFIX/share/games/$ID
DOCPATH=$PREFIX/share/doc/$ID
BINPATH=$PREFIX/games
DESKPATH=$PREFIX/share/applications
ICONPATH=/usr/local/share/icons/hicolor/128x128/apps
mkdir -p $PKGNAME1$GAMEPATH $PKGNAME1$DOCPATH $PKGNAME1$BINPATH $PKGNAME1$DESKPATH $PKGNAME1$ICONPATH $PKGNAME1/DEBIAN
mv $TMPDIR/*/game/* $PKGNAME1$GAMEPATH
mv $TMPDIR/*/docs/* $PKGNAME1$DOCPATH
cp -al $PKGNAME1 $PKGNAME2
rm -r $PKGNAME1$GAMEPATH/$EXE2 $PKGNAME1$GAMEPATH/lib64 $PKGNAME2$GAMEPATH/$EXE1 $PKGNAME2$GAMEPATH/lib

# Création des lanceurs
echo "#!/bin/sh -e
cd $GAMEPATH
./$EXE1 \$@
exit 0" > $PKGNAME1$BINPATH/$ID

echo "#!/bin/sh -e
cd $GAMEPATH
./$EXE2 \$@
exit 0" > $PKGNAME2$BINPATH/$ID

chmod 755 $PKGNAME1$BINPATH/* $PKGNAME2$BINPATH/*

# Création des entrées de menu
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game" > $PKGNAME1$DESKPATH/$ID.desktop

cp -l $PKGNAME1$DESKPATH/$ID.desktop $PKGNAME2$DESKPATH

# Création des fichiers DEBIAN/control
echo "Package: $ID
Version: $VERSION-gog$REVISION
Section: non-free/games
Architecture: $ARCH1
Installed-Size: $(du -ks $PKGNAME1/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts: $ID:$ARCH2
Description: $PKGDESC" > $PKGNAME1/DEBIAN/control

echo "Package: $ID
Version: $VERSION-gog$REVISION
Section: non-free/games
Architecture: $ARCH2
Installed-Size: $(du -ks $PKGNAME2/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts: $ID:$ARCH1
Description: $PKGDESC" > $PKGNAME2/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/defcon.png $ICONPATH
ln -s $GAMEPATH/*.txt $DOCPATH
exit 0" > $PKGNAME1/DEBIAN/postinst

echo "#!/bin/sh -e
rm $ICONPATH/* $DOCPATH/*
exit 0" > $PKGNAME1/DEBIAN/prerm

chmod 755 $PKGNAME1/DEBIAN/postinst $PKGNAME1/DEBIAN/prerm
cp -l $PKGNAME1/DEBIAN/postinst $PKGNAME1/DEBIAN/prerm $PKGNAME2/DEBIAN

# Construction du paquet
for pkgname in $PKGNAME1 $PKGNAME2; do
	$DPKGDEB $pkgname
	rm -r $pkgname
done
rm -r $TMPDIR
echo "Paquets construits."
echo "Installez-la version $ARCH1 en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME1.deb; apt-get install -f"
echo "Installez-la version $ARCH2 en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME2.deb; apt-get install -f"

exit 0
