#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in unzip convert fakeroot; do
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
ID=fez
VERSION=1.11
REVISION=20140624
ARCH1=i386
ARCH2=amd64
EXE1="FEZ.bin.x86"
EXE2="FEZ.bin.x86_64"
ICON="FEZ.bmp"
ICONRES=/usr/local/share/icons/hicolor/$ICONRES/apps
DESKNAME="FEZ"
PKGDESC="FEZ"
PKGDEPS="libc6, libgcc1, libstdc++6"
ARCHIVE="fez-06242014-bin"
MD5SUM=b4178a11a0afff13cf264d852bf773df

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
DPKGDEB="fakeroot -- dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ $1 ]; then
	if [ -f "$ARCHIVE" ]; then
		echo "Utilisation de $(realpath "$ARCHIVE")"
	else
		echo "Ce script prend en premier argument l’archive téléchargée depuis humblebundle.com. ($ARCHIVE)"
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

# Préparation de l’arborescence des paquets
PKGNAME1="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH1
PKGNAME2="$ID"_$VERSION-humblebundle"$REVISION"_$ARCH2
for pkgname in $PKGNAME1 $PKGNAME2; do
	if [ -e $pkgname ]; then
		echo "$(realpath $pkgname) existe déjà, il peut s’agir d’un résidu d’une utilisation du script avortée."
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
ICONPATH=/usr/local/share/icons/hicolor/$ICONRES/apps
DESKPATH=$PREFIX/share/applications
mkdir -p $PKGNAME1$GAMEPATH $PKGNAME1$DOCPATH $PKGNAME1$BINPATH $PKGNAME1$ICONPATH $PKGNAME1$DESKPATH $PKGNAME1/DEBIAN
cp -r $PKGNAME1 $PKGNAME2

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
unzip -d $TMPDIR $ARCHIVE 2>/dev/null || true
find $TMPDIR/data -type f -exec chmod 644 {} +
chmod 755 $TMPDIR/data/$EXE1 $TMPDIR/data/$EXE2
cp -al $TMPDIR/data/* $PKGNAME1$GAMEPATH
cp -al $TMPDIR/data/* $PKGNAME2$GAMEPATH
rm -r $PKGNAME1$GAMEPATH/lib64 $PKGNAME1$GAMEPATH/$EXE2
rm -r $PKGNAME2$GAMEPATH/lib $PKGNAME2$GAMEPATH/$EXE1

# Conversion de l'icône
convert $TMPDIR/data/$ICON $TMPDIR/$ID.png 2>/dev/null
cp -al $TMPDIR/$ID.png $PKGNAME1$ICONPATH
cp -al $TMPDIR/$ID.png $PKGNAME2$ICONPATH

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
Categories=Game;" > $PKGNAME1$DESKPATH/$ID.desktop
cp -al $PKGNAME1$DESKPATH/$ID.desktop $PKGNAME2$DESKPATH

# Création des fichiers DEBIAN/control
echo "Package: $ID
Version: $VERSION-humbledundle$REVISION
Section: non-free/games
Architecture: $ARCH1
Installed-Size: $(du -ks $PKGNAME1/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts: $ID:$ARCH2
Description: $PKGDESC" > $PKGNAME1/DEBIAN/control

echo "Package: $ID
Version: $VERSION-humbledundle$REVISION
Section: non-free/games
Architecture: $ARCH2
Installed-Size: $(du -ks $PKGNAME2/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Conflicts: $ID:$ARCH1
Description: $PKGDESC" > $PKGNAME2/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/Linux.README $DOCPATH
exit 0" > $PKGNAME1/DEBIAN/postinst

echo "#!/bin/sh -e
find $DOCPATH -type l -delete
exit 0" > $PKGNAME1/DEBIAN/prerm

chmod 755 $PKGNAME1/DEBIAN/postinst $PKGNAME1/DEBIAN/prerm
cp -al $PKGNAME1/DEBIAN/postinst $PKGNAME1/DEBIAN/prerm $PKGNAME2/DEBIAN

# Construction des paquets
rm -r $TMPDIR
for pkgname in $PKGNAME1 $PKGNAME2; do
	$DPKGDEB $pkgname
	rm -r $pkgname
done

echo "Paquets construits."
echo "Installez la version $ARCH1 en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME1.deb; apt-get install -f"
echo "Installez la version $ARCH2 en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME2.deb; apt-get install -f"

exit 0
