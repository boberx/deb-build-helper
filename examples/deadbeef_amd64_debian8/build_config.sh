VERSION="0.7.2";

APP_PCKG_MAINTAINER="Bober <boberx@gmail.com>";

APP_TEST_BUILD="false";

APP_DEB_PCKG="deadbeef";

APP_SRC_ARCH="${B_APP_ROOT_PATH}/"${APP_DEB_PCKG}"-"${VERSION}".tar.bz2";

APP_VERSION=""${VERSION}"-bober8+${B_APP_BLD_VER}";

APP_SRC_DIR=""${B_APP_ROOT_PATH}"/"${B_APP_BDATE}"/"${APP_DEB_PCKG}"-"${VERSION}"";

APP_REQ_PCKGAV="\
make \
gcc \
intltool \
pkg-config \
libjansson-dev:amd64 \
g\+\+ \
zlib1g-dev:amd64 \
libgtk-3-dev:amd64 \
libasound2-dev:amd64 \
libmad0-dev \
libflac-dev:amd64 \
libvorbis-dev:amd64 \
libpulse-dev:amd64";

APP_HOMEPAGE="http://deadbeef.sourceforge.net/";

APP_CFLAGS="-O2";

APP_CFG_OPTS="\
--prefix=/usr \
--enable-portable=full \
--disable-oss \
--disable-coreaudio \
--disable-nullout \
--disable-vfs-curl \
--disable-lfm \
--disable-artwork \
--disable-artwork-network \
--disable-sid \
--disable-ffap \
--disable-vtx \
--disable-adplug \
--disable-gme \
--disable-gtk2 \
--enable-shared=yes";
