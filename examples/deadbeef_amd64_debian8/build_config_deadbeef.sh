APP_DEB_PCKG_deadbeef_DESCRIPTION="DeaDBeeF (as in 0xDEADBEEF) is a cross-platform audio player.
 .
 Main features (the list is most likely far from complete):
 .
 - mp3, ogg vorbis, flac, ape, wv/iso.wv, wav, m4a/mp3 (aac and alac), mpc, tta, cd audio, and many more
 - nsf, ay, vtx, vgm/vgz, spc and many other popular chiptune formats
 - SID with HVSC song length database support for sid
 - tracker modules - mod, s3m, it, xm, etc
 - ID3v1, ID3v2.2, ID3v2.3, ID3v2.4, APEv2, Xing/Info, VorbisComments tag reading and writing, as well as reading many other tag/metadata formats in most supported formats
 - automatic character set detection for non-unicode id3 tags - supports cp1251, iso8859-1, and now chinese cp936 (optional), as well as SHIFT-JIS and MS-DOS CP866 for selected formats
 - unicode tags are fully supported as well (both utf8 and ucs2)
 - cuesheet (.cue files) support, including charset detection/conversion
 - clean fast GUI using GTK2 and GTK3, you pick what you like more!
 - no GNOME or KDE dependencies
 - minimization to system tray, with scrollwheel volume control, etc
 - drag and drop, both in playlist, and from other apps
 - control playback from command line
 - global hotkeys
 - multiple playlists using tabbed interface
 - album cover display
 - OSD notifications about current playing songs
 - 18-band graphical equalizer and other DSP plugins
 - built-in high quality tag editor, with custom fields support
 - customizable groups in playlists
 - customizable columns with flexible title formatting
 - streaming radio support for ogg vorbis, mp3 and aac streams
 - gapless playback for correctly encoded files
 - lots of plugin, such as global hotkeys, last.fm scrobbler, converter, and many more, sdk is included
 - comes with advanced Converter plugin, which allows to transcode files to other formats
 was tested on x86, x86_64, powerpc, arm, mips architectures, should work on most modern platforms
";

APP_DEB_PCKG_deadbeef_ARCH="amd64";

APP_DEB_PCKG_deadbeef_PRIORITY="optional";

APP_DEB_PCKG_deadbeef_SECTION="sound";

APP_DEB_PCKG_deadbeef_DEPENDS=""$(app_get_last_pckg_ver libc6)",libjansson4";

deadbeef()
{
	cp "${APP_SRC_DIR}"/deadbeef.desktop		"${1}"/usr/share/applications/;
	cp "${APP_SRC_DIR}"/deadbeef				"${1}"/usr/bin/;

	for filefullpath  in `find "${APP_SRC_DIR}"/plugins/*/.libs -mindepth 1 -maxdepth 1 -type f -name "*\.so"`; do
		cp "${filefullpath}"	"${1}"/usr/lib/deadbeef/;
	done;

	for filefullpath in `find "${APP_SRC_DIR}"/pixmaps/ -mindepth 1 -maxdepth 1 -type f -name "*\.png"`; do
		cp "${filefullpath}"	"${1}"/usr/share/deadbeef/pixmaps/;
	done;

	for filefullpath in `find "${APP_SRC_DIR}"/icons/*/ -mindepth 1 -maxdepth 1 -type f -regex ".*\.\(svg\|png\)"`; do
		r="$(dirname $filefullpath)";
		mkdir -p "${1}"/usr/share/icons/hicolor/"${r##*/}"/apps/ && \
		cp "${filefullpath}"	"${1}"/usr/share/icons/hicolor/"${r##*/}"/apps/;
	done;

	for filefullpath in `find "${APP_SRC_DIR}"/po/ -mindepth 1 -maxdepth 1 -type f -name "*\.gmo"`; do
		r=${filefullpath%.gmo};
		mkdir -p "${1}"/usr/share/locale/"$(basename "$r")"/LC_MESSAGES/ &&
		cp "${filefullpath}"	"${1}"/usr/share/locale/"$(basename "$r")"/LC_MESSAGES/;
	done;

	cp -r "${APP_SRC_DIR}"/plugins/converter/convpresets	"${1}"/usr/lib/deadbeef/;

	app_strip "${1}";
	app_set_default_permissions "${1}";

	return 0;
}
