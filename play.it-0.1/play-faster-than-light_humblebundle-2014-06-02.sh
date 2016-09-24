#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in convert fakeroot; do
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
ID=faster-than-light
VERSION=1.5.13
REVISION=140602
ARCH1=i386
ARCH2=amd64
PKGDESC="Faster Than Light"
PKGDEPS="libgl1-mesa-glx, libc6, libstdc++6, libexpat1, libglapi-mesa, libxext6, libxdamage1, libxfixes3, libx11-xcb1, libx11-6, libxcb-glx0, libxcb-dri2-0, libxcb1, libxxf86vm1, libdrm2, libgcc1, libxau6, libxdmcp6"
EXE=FTL
ICON=exe_icon.bmp
DESKNAME="Faster Than Light"
ARCHIVE=FTL.1.5.13.tar.gz
MD5SUM=791e0bc8de73fcdcd5f461a4548ea2d8

# Définition de la méthode de compression pour le paquet final
if [ -z $COMPRESSION ]; then
	COMPRESSION=none
fi
if [ $COMPRESSION = none ]; then
	echo "Le paquet final sera construit sans compression."
elif [ $COMPRESSION = gzip -o $COMPRESSION = xz ]; then
	echo "Le paquet final sera compressé via $COMPRESSION."
else
	echo "La variable \$COMPRESSION n’est pas définie à une valeur autorisée."
	echo "Ces valeurs sont : none, gzip, xz"
	exit 1
fi
DPKGDEB="fakeroot dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ $1 ]; then
	if [ -f $ARCHIVE ]; then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’archive téléchargée depuis humblebundle.com. ($ARCHIVE)"
		exit 1
	fi
elif ! [ -f $1  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE=$1
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
PKGNAME1="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH1
PKGNAME2="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH2
for pkgname in $PKGNAME1 $PKGNAME2; do
	if [ -e $pkgname ]; then
		echo "$pkgname existe déjà, il peut s’agir d’un résidu d’une utilisation du script avortée."
		echo "Supprimez-le avant de relancer ce script."
		exit 1
	fi
done
if [ -z $PREFIX ]; then
	PREFIX=/usr/local
fi
echo "\$PREFIX défini à \"$PREFIX\""
if ! [ "$( echo $PREFIX | cut -c1)" = "/" ]; then
	echo "\$PREFIX doit être un chemin absolu."
	exit 1
fi
GAMEPATH=$PREFIX/share/games/$ID
DOCPATH=$PREFIX/share/doc/$ID
BINPATH=$PREFIX/games
DESKPATH=$PREFIX/share/applications
ICONPATH=/usr/local/share/icons/hicolor/64x64/apps
for pkgname in $PKGNAME1 $PKGNAME2; do
	mkdir -p $pkgname$GAMEPATH $pkgname$DOCPATH $pkgname$BINPATH $pkgname$DESKPATH $pkgname$ICONPATH $pkgname/DEBIAN
done

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
mkdir $TMPDIR
tar xvf "$ARCHIVE" -C $TMPDIR
chmod 644 $TMPDIR/FTL/data/resources/*
for pkgname in $PKGNAME1 $PKGNAME2; do
	cp -al $TMPDIR/FTL/* $pkgname$GAMEPATH
done
rm -r $PKGNAME1$GAMEPATH/data/amd64
rm -r $PKGNAME2$GAMEPATH/data/x86

# Conversion de l’icône
convert $PKGNAME1$GAMEPATH/data/$ICON $PKGNAME1$ICONPATH/$ID.png
cp -l $PKGNAME1$ICONPATH/$ID.png $PKGNAME2$ICONPATH

# Création du lanceur
echo "#!/bin/sh -e
cd $GAMEPATH
./$EXE \$@
exit 0" > $PKGNAME1$BINPATH/$ID

chmod 755 $PKGNAME1$BINPATH/*
cp -l $PKGNAME1$BINPATH/$ID $PKGNAME2$BINPATH

# Création de l’entrée de menu
echo "[Desktop Entry]
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > $PKGNAME1$DESKPATH/$ID.desktop

cp -l $PKGNAME1$DESKPATH/$ID.desktop $PKGNAME2$DESKPATH

# Remplissage des fichiers DEBIAN/control
echo "Package: $ID
Version: $VERSION-humblebundle$REVISION
Section: non-free/games
Architecture: $ARCH1
Installed-Size: $(du -ks $PKGNAME1/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts:$ID:$ARCH2
Description: $PKGDESC" > $PKGNAME1/DEBIAN/control

echo "Package: $ID
Version: $VERSION-humblebundle$REVISION
Section: non-free/games
Architecture: $ARCH2
Installed-Size: $(du -ks $PKGNAME2/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts:$ID:$ARCH1
Description: $PKGDESC" > $PKGNAME2/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/*.html $GAMEPATH/licenses $DOCPATH
exit 0" > $PKGNAME1/DEBIAN/postinst

echo "#!/bin/sh -e
rm $DOCPATH/*
exit 0" > $PKGNAME1/DEBIAN/prerm

chmod 755 $PKGNAME1/DEBIAN/postinst $PKGNAME1/DEBIAN/prerm
cp -l $PKGNAME1/DEBIAN/postinst $PKGNAME2/DEBIAN
cp -l $PKGNAME1/DEBIAN/prerm $PKGNAME2/DEBIAN

# Construction des paquets
rm -r $TMPDIR
for pkgname in $PKGNAME1 $PKGNAME2; do
	$DPKGDEB $pkgname
	rm -r $pkgname
done

echo "Paquets construits."
echo "Installez-la version 32-bit en lançant la commande suivante (en root) :"
echo "dpkg -i $PWD/$PKGNAME1.deb; apt-get install -f"
echo "Installez-la version 64-bit en lançant la commande suivante (en root) :"
echo "dpkg -i $PWD/$PKGNAME2.deb; apt-get install -f"

exit 0
