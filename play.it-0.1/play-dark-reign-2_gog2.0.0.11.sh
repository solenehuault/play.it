#!/bin/sh -e

for dep in innoextract wrestool icotool fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable sur votre système"
		echo "Installez-le avant de relancer ce script."
	fi
done

ID=dark-reign-2
VERSION=1.3.882
REVISION=2.0.0.11
ARCH=all
GAMEEXE=dr2.exe
ICONRES="16x16 32x32"
DESKNAME="Dark Reign 2"
PKGDEPS="wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386"
PKGDESC="Dark Reign 2"
ARCHIVE=setup_dark_reign2_2.0.0.11.exe

if ! [ "$1" ]; then
	if [ -f $ARCHIVE ]; then
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce cript prend en argument l’installeur téléchargé depuis gog.com. (version $VERSION)"
		exit 1
	fi
elif ! [ -f "$1"  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE="$1"
fi

# Extraction de l’installeur
TMPDIR=$ID.$(date +%s)
innoextract -seL -p -d $TMPDIR "$ARCHIVE"

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_"$VERSION"-"$REVISION"_"$ARCH"
mkdir -p $PKGNAME/usr/local/share/doc/$ID
mv $TMPDIR/app/*.htm $TMPDIR/app/*.pdf $TMPDIR/app/*.rtf $TMPDIR/app/*.txt $PKGNAME/usr/local/share/doc/$ID
mkdir -p $PKGNAME/usr/local/share/games/$ID
mv $TMPDIR/app/* $PKGNAME/usr/local/share/games/$ID
rm -r $TMPDIR

# Extraction des icônes
wrestool -t 14 -x $PKGNAME/usr/local/share/games/$ID/dr2.exe | icotool -x -
for res in $ICONRES
do
	mkdir -p $PKGNAME/usr/local/share/icons/hicolor/"$res"/apps
	mv *"$res"x*.png $PKGNAME/usr/local/share/icons/hicolor/"$res"/apps/$ID.png
done

# Création des lanceurs
mkdir -p $PKGNAME/usr/local/games
echo "#!/bin/sh
ID=$ID
EXE=$GAMEEXE
USERDIR=\$HOME/.local/share/games/\$ID

export WINEPREFIX=\$USERDIR/.wine
export WINEDEBUG=-all

if ! [ -d \$USERDIR ]; then
	mkdir -p \$(dirname \$USERDIR)
	INSTALLDIR=/usr/local/share/games/\$ID
	cp -as \$INSTALLDIR \$USERDIR
	WINEARCH=win32 wineboot -i
	rm \$WINEPREFIX/dosdevices/"z:"
	ln -s \$USERDIR \$WINEPREFIX/drive_c
fi

cd \$WINEPREFIX/drive_c/\$ID
wine \$EXE" > $PKGNAME/usr/local/games/$ID
chmod 755 $PKGNAME/usr/local/games/$ID
mkdir -p $PKGNAME/usr/local/share/applications
echo "[Desktop Entry]
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > $PKGNAME/usr/local/share/applications/$ID.desktop

# Remplissage du fichier DEBIAN/control
mkdir $PKGNAME/DEBIAN
echo "Package: $ID
Version: $VERSION-$REVISION
Section: non-free/games
Architecture: $ARCH
Installed-Size: $(du -ks $PKGNAME/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Description: $PKGDESC" > $PKGNAME/DEBIAN/control

# Construction du paquet
fakeroot dpkg-deb -Znone -b $PKGNAME
rm -r $PKGNAME

exit 0
