#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in md5sum unar wrestool icotool fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable sur votre système."
		echo "Installez-le avant de relancer ce script."
		exit 1
	fi
done

# Initialisation des variables
ID=star-wars-battlefront-2
VERSION=1.1
REVISION=2.0.0.5
ARCH=all
PKGDESC="Star Wars: Battlefront 2"
PKGDEPS="wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386"
EXE=BattlefrontII.exe
ICONRES=/usr/local/share/icons/hicolor/$iconres/apps
ICONDUMP="*x4.png"
DESKNAME="Star Wars: Battlefront II"
ARCHIVE=setup_sw_battlefront2_2.0.0.5.exe
GAMEID=1421404701
MD5SUM1=dc36b03c9c43fb8d3cb9b92c947daaa4
MD5SUM2=5d4000fd480a80b6e7c7b73c5a745368

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
if ! [ $1 ]
then
	if [ -f $ARCHIVE ]
	then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’archive téléchargée depuis GOG.com. ($ARCHIVE)"
		exit 1
	fi
elif ! [ -f $1  ]
then
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
	if [ "$(md5sum "$(basename $ARCHIVE .exe)-1.bin" | cut -d' ' -f1)" != "$MD5SUM1" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $(basename $ARCHIVE .exe)-1.bin n’est pas celui attendu, ou il est corrompu."
		exit 1
	elif [ "$(md5sum "$(basename $ARCHIVE .exe)-2.bin" | cut -d' ' -f1)" != "$MD5SUM2" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $(basename $ARCHIVE .exe)-2.bin n’est pas celui attendu, ou il est corrompu."
		exit 1
	fi
fi

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_$VERSION-gog"$REVISION"_$ARCH
if [ -e $PKGNAME ]; then
	echo "$(realpath $PKGNAME) existe déjà, il peut s’agir d’un résidu d’une utilisation du script avortée."
	echo "Supprimez-le avant de relancer ce script."
	exit 1
fi
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
mkdir -p $PKGNAME$GAMEPATH $PKGNAME$DOCPATH $PKGNAME$BINPATH $PKGNAME$DESKPATH $PKGNAME/DEBIAN

# Calcul du mot de passe
PASSWD=$(echo -n $GAMEID | md5sum | cut -d' ' -f1)

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
mkdir $TMPDIR
ln -s $(dirname $(realpath $ARCHIVE))/$(basename $ARCHIVE .exe)-1.bin $TMPDIR/$(basename $ARCHIVE .exe).r00
ln -s $(dirname $(realpath $ARCHIVE))/$(basename $ARCHIVE .exe)-2.bin $TMPDIR/$(basename $ARCHIVE .exe).r01
unar -o $TMPDIR -D -p $PASSWD $TMPDIR/$(basename $ARCHIVE .exe).r00
mv $TMPDIR/game/GameData/* $PKGNAME$GAMEPATH
mv $TMPDIR/game/*.pdf $PKGNAME$DOCPATH

# Extraction des icônes
wrestool -t 14 -x $PKGNAME$GAMEPATH/$EXE | icotool -x -o $TMPDIR -
rm $TMPDIR/$ICONDUMP
for iconres in $ICONRES; do
	ICONPATH=/usr/local/share/icons/hicolor/$iconres/apps
	mkdir -p $PKGNAME$ICONPATH
	mv $TMPDIR/*"$iconres"x*.png $PKGNAME$ICONPATH/$ID.png
done

# Création du lanceur
echo "#!/bin/sh -e
USERDIR=\$HOME/.local/share/games/$ID
if ! [ -e \$USERDIR/$EXE ]; then
	mkdir -p \$USERDIR
	cp -surf $GAMEPATH/* \$USERDIR
fi
export WINEPREFIX=\$USERDIR/wine-prefix
export WINEDEBUG=-all
if ! [ -e \$WINEPREFIX ]; then
	WINEARCH=win32 wineboot -i
	rm \$WINEPREFIX/dosdevices/z:
	ln -s \$USERDIR \$WINEPREFIX/drive_c
fi
cd \$WINEPREFIX/drive_c/$ID
wine $EXE \$@
exit 0" > $PKGNAME$BINPATH/$ID

chmod 755 $PKGNAME$BINPATH/*

# Création de l’entrée de menu
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

# Construction du paquet
rm -r $TMPDIR
$DPKGDEB $PKGNAME
rm -r $PKGNAME

echo "Paquet construit."
echo "Installez-le en lançant la commande suivante (en root) :"
echo "dpkg -i $PWD/$PKGNAME.deb ; apt-get install -f"

exit 0
