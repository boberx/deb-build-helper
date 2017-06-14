#!/bin/sh

if [ -x "/etc/init.d/dcc-client" ]; then
	update-rc.d dcc-client defaults >/dev/null && \
	chown dccuser:dccgroup /var/lib/dcc/ && \
	chown dccuser:dccgroup /usr/local/sbin/dccifd && \
	chmod 705 /var/lib/dcc && \
	chmod 100 /usr/local/sbin/dccifd && \
	chown dccuser:dccgroup /var/lib/dcc/map && \
	chmod 600 /var/lib/dcc/map && \
	chown dccuser:dccgroup /var/lib/dcc/whiteclnt && \
	chown dccuser:dccgroup /var/lib/dcc/whitecommon && \
	chmod 600 /var/lib/dcc/whiteclnt && \
	chmod 600 /var/lib/dcc/whitecommon && \
	if [ -x "/etc/init.d/dcc-client" ]; then
		/etc/init.d/dcc-client start
		exit 0
	fi
fi
exit 1
