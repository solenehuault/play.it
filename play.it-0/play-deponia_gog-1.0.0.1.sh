#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in realpath md5sum fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable sur votre système."
		echo "Installez-le avant de relancer ce script."
		exit 1
	fi
done

# Initialisation des variables
ID=deponia
VERSION=3.2.3.1334
REVISION=1.0.0.1
ARCH=amd64
PKGDESC="Deponia"
PKGDEPS="libasound2, libasyncns0, libattr1, libavcodec56, libavdevice55, libavformat56, libavresample2, libavutil54, libbz2-1.0, libc6, libcap2, libcdio13, libcdio-cdda1, libcdio-paranoia1, libdbus-1-3, libdc1394-22, libdrm2, libexpat1, libffi6, libflac8, libgcc1, libgcrypt20, libgl1-mesa-glx, libglapi-mesa, libgmp10, libgnutls-deb0-28, libgpg-error0, libgsm1, libhogweed2, libice6, libjack-jackd2-0, libjson-c2, liblzma5, libmp3lame0, libnettle4, libogg0, libopenal1, libopenjpeg5, libopus0, liborc-0.4-0, libp11-kit0, libpulse0, libraw1394-11, librtmp1, libschroedinger-1.0-0, libsm6, libsndfile1, libspeex1, libstdc++6, libsystemd0, libtasn1-6, libtheora0, libudev1, libusb-1.0-0, libuuid1, libva1, libvorbis0a, libvorbisenc2, libvpx1, libwrap0, libx11-6, libx11-xcb1, libx264-142, libxau6, libxcb1, libxcb-dri2-0, libxcb-dri3-0, libxcb-glx0, libxcb-present0, libxcb-sync1, libxdamage1, libxdmcp6, libxext6, libxfixes3, libxi6, libxshmfence1, libxtst6, libxvidcore4, libxxf86vm1, zlib1g"
EXE=Deponia
DESKNAME="Deponia"
ARCHIVE=gog_deponia_1.0.0.1.tar.gz
MD5SUM=eecdcdceef7baf7095a2c0737dc6dd56

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
		echo "Ce script prend en argument l’archive téléchargée depuis gog.com. ($ARCHIVE)"
		exit 1
	fi
elif ! [ -f "$1"  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE="$1"
fi
echo "Contrôle de l’intégrité de l’archive…"
if [ "$(md5sum "$ARCHIVE" | cut -d' ' -f1)" != "$MD5SUM" ]; then
	echo "Somme de contrôle incohérente."
	echo "Le fichier $ARCHIVE n’est pas celui attendu, ou il est corrompu."
	exit 1
fi
echo "OK"

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_$VERSION-gog"$REVISION"_$ARCH
PREFIX=/usr/local
GAMEPATH=$PREFIX/share/games/$ID
DOCPATH=$PREFIX/share/doc/$ID
BINPATH=$PREFIX/games
DESKPATH=$PREFIX/share/applications
ICONPATH=/usr/local/share/icons/hicolor/128x128/apps
mkdir -p $PKGNAME$GAMEPATH $PKGNAME$DOCPATH $PKGNAME$BINPATH $PKGNAME$ICONPATH $PKGNAME$DESKPATH $PKGNAME/DEBIAN

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
mkdir $TMPDIR
tar xvf "$ARCHIVE" -C $TMPDIR
rm $TMPDIR/*/game/start
find $TMPDIR/*/game -type f -not -name Deponia -execdir chmod 644 {} +
mv $TMPDIR/*/game/* $PKGNAME$GAMEPATH
mv $TMPDIR/*/docs/* $PKGNAME$DOCPATH
mv $TMPDIR/*/support/gog-deponia.png $PKGNAME$ICONPATH/$ID.png

# Création du lanceur
echo "#!/bin/sh -e
if [ -z \$XDG_DATA_HOME ]; then
	export XDG_DATA_HOME=$HOME/.local/share
fi
LOGPATH=\"\$XDG_DATA_HOME/Daedalic Entertainment/Deponia/messages.log\"
cd $GAMEPATH
export LD_LIBRARY_PATH=./libs64:\"\$LD_LIBRARY_PATH\"
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
ln -s $GAMEPATH/*.txt $GAMEPATH/documents/licenses/* $DOCPATH
exit 0" > $PKGNAME/DEBIAN/postinst

echo "#!/bin/sh -e
find $DOCPATH -type l -delete
exit 0" > $PKGNAME/DEBIAN/prerm

chmod 755 $PKGNAME/DEBIAN/postinst $PKGNAME/DEBIAN/prerm

# Construction du paquet
$DPKGDEB $PKGNAME
rm -r $PKGNAME $TMPDIR
echo "Paquet construit."
echo "Installez-le en lançant en root :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0
