APP_DEB_PCKG_dcc_client_DESCRIPTION="Distributed Checksum Clearinghouse
 .
 The Distributed Checksum Clearinghouses or DCC is an anti-spam content filter that runs on a variety of operating systems.
 The counts can be used by SMTP servers and mail user agents to detect and reject or filter spam or unsolicited bulk mail.
 DCC servers exchange or \"flood\" common checksums. The checksums include values that are constant across common variations in bulk messages, including \"personalizations\"";

APP_DEB_PCKG_dcc_client_SECTION="mail";

APP_DEB_PCKG_dcc_client_PRIORITY="optional";

APP_DEB_PCKG_dcc_client_ARCH="i386";

APP_DEB_PCKG_dcc_client_CONFFILES="/etc/default/dcc
/var/lib/dcc/whiteclnt
/var/lib/dcc/whitecommon
/etc/spamassassin/dcc.pre";

dcc_client()
{
	cp "${2}"/build_config_dcc_client.whiteclnt				"${1}"/var/lib/dcc/whiteclnt;
	cp "${2}"/build_config_dcc_client.whitecommon			"${1}"/var/lib/dcc/whitecommon;
	cp "${2}"/build_config_dcc_client.spamassassin.dcc.pre	"${1}"/etc/spamassassin/dcc.pre;
	cp "${2}"/build_config_dcc_client.default.dcc			"${1}"/etc/default/dcc;
	cp "${2}"/build_config_dcc_client.initd.dcc-client		"${1}"/etc/init.d/dcc-client;

	cp "${APP_SRC_DIR}"/cdcc/cdcc						"${1}"/usr/local/bin/cdcc;
	cp "${APP_SRC_DIR}"/dccifd/dccifd					"${1}"/usr/local/sbin/dccifd;

	cp "${APP_SRC_DIR}"/homedir/map						"${1}"/var/lib/dcc/map;
	cp "${APP_SRC_DIR}"/homedir/map.txt					"${1}"/var/lib/dcc/map.txt;

	app_strip "${1}";
	app_set_default_permissions "${1}";

	return 0;
}
