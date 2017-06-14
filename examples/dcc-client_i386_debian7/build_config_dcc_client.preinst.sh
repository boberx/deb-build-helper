#!/bin/sh
case "$1" in
	install|upgrade)
		if ! getent group | grep -q ^dccgroup:; then
			echo -n "Adding group dccgroup.."
			addgroup --quiet --system dccgroup 2>/dev/null ||true
			echo "..done"
		fi

		if ! getent passwd | grep -q ^dccuser:; then
			echo -n "Adding system user dccuser.."
			adduser --quiet \
				--system \
				--ingroup dccgroup \
				--no-create-home \
				--home /var/lib/dcc \
				--disabled-password \
				dccuser 2>/dev/null || true
			echo "..done"
		fi
esac
exit 0
