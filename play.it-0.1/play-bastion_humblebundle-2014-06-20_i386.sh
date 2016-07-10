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
ID=bastion
VERSION=1.2
REVISION=120620
ARCH=i386
PKGDESC="Bastion"
PKGDEPS="libc6, libgcc1, libstdc++6"
EXE=Bastion.bin.x86
DESKNAME="Bastion"
ARCHIVE=Bastion-HIB-2012-06-20.sh
MD5SUM=aa6ccaead3b4b8a5fbd156f4019e8c8b

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
DPKGDEB="fakeroot dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ $1 ]; then
	if [ -f $ARCHIVE ]; then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’archive téléchargée depuis gog.com. (version $REVISION)"
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
PKGNAME="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH
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
ICONPATH=/usr/local/share/icons/hicolor/256x256/apps
mkdir -p $PKGNAME$GAMEPATH $PKGNAME$DOCPATH $PKGNAME$BINPATH $PKGNAME$DESKPATH $PKGNAME$ICONPATH $PKGNAME/DEBIAN

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
mkdir $TMPDIR
fakeroot linux32 sh "$ARCHIVE" -u -b $PWD/$TMPDIR -d $PWD/$TMPDIR
find $TMPDIR -type f -exec chmod 644 {} +
chmod 755 $TMPDIR/Bastion/$EXE
mv $TMPDIR/Bastion/* $PKGNAME$GAMEPATH

# Création du lanceur
echo "#!/bin/sh -e
cd $GAMEPATH
./$EXE \$@
exit 0" > $PKGNAME$BINPATH/$ID
chmod 755 $PKGNAME$BINPATH/*

# Création de l’entrée de menu
echo "[Desktop Entry]
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > $PKGNAME$DESKPATH/$ID.desktop

# Remplissage du fichier DEBIAN/control
echo "Package: $ID
Version: $VERSION-humblebundle$REVISION
Section: non-free/games
Architecture: $ARCH
Installed-Size: $(du -ks $PKGNAME/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts: $ID:amd64
Description: $PKGDESC" > $PKGNAME/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/Bastion.png $ICONPATH/$ID.png
ln -s $GAMEPATH/README.linux $DOCPATH
exit 0" > $PKGNAME/DEBIAN/postinst

echo "#!/bin/sh -e
rm $ICONPATH/$ID.png $DOCPATH/*
exit 0" > $PKGNAME/DEBIAN/prerm

chmod 755 $PKGNAME/DEBIAN/postinst $PKGNAME/DEBIAN/prerm

# Construction des paquets
$DPKGDEB $PKGNAME
rm -r $PKGNAME $TMPDIR
echo "Paquet construit."
echo "Installez-le en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0
