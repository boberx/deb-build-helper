VERSION="1.3.159";

APP_PCKG_MAINTAINER="Bober <boberx@gmail.com>";

APP_TEST_BUILD="false";

APP_SRC_ARCH="${B_APP_ROOT_PATH}/dcc.tar.Z";

APP_DEB_PCKG="dcc-client";

APP_VERSION=""${VERSION}"-debian7+"${B_APP_BLD_VER}"";

APP_SRC_DIR=""${B_APP_ROOT_PATH}"/"${B_APP_BDATE}"/dcc-"${VERSION}"";

APP_HOMEPAGE="http://www.dcc-servers.net/";

APP_CFLAGS="-O2";

if [ ! -f "${B_APP_ROOT_PATH}"/build_config_dcc_client.default.dcc ]; then
	echo "Error: file \"build_config_dcc_client.default.dcc\"" does not exist...;
	exit 1;
fi;

. "${B_APP_ROOT_PATH}"/build_config_dcc_client.default.dcc;

APP_CFG_OPTS="--disable-sys-inst --with-uid="${DCC_USER}" --disable-server --disable-dccm --homedir="${DCC_HOMEDIR}" --bindir="${DCC_BINDIR}"";
