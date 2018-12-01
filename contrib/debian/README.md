
Debian
====================
This directory contains files used to package stintcoind/stintcoin-qt
for Debian-based Linux systems. If you compile stintcoind/stintcoin-qt yourself, there are some useful files here.

## stintcoin: URI support ##


stintcoin-qt.desktop  (Gnome / Open Desktop)
To install:

	sudo desktop-file-install stintcoin-qt.desktop
	sudo update-desktop-database

If you build yourself, you will either need to modify the paths in
the .desktop file or copy or symlink your stintcoinqt binary to `/usr/bin`
and the `../../share/pixmaps/stintcoin128.png` to `/usr/share/pixmaps`

stintcoin-qt.protocol (KDE)

