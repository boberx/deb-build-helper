#!/bin/sh

if [ "$1" = "purge" ] ; then
# find first and last SYSTEM_UID numbers
for LINE in `grep SYSTEM_UID /etc/adduser.conf | grep -v "^#"`; do
	case $LINE in
		FIRST_SYSTEM_UID*)
		FIST_SYSTEM_UID=`echo $LINE | cut -f2 -d '='`
		;;
		LAST_SYSTEM_UID*)
		LAST_SYSTEM_UID=`echo $LINE | cut -f2 -d '='`
		;;
		*)
		;;
	esac
done

# Remove system account if necessary
CREATEDUSER="dccuser"
if [ -n "$FIST_SYSTEM_UID" ] && [ -n "$LAST_SYSTEM_UID" ]; then
	if USERID=`getent passwd $CREATEDUSER | cut -f 3 -d ':'`; then
		if [ -n "$USERID" ]; then
			if [ "$FIST_SYSTEM_UID" -le "$USERID" ] && \
				[ "$USERID" -le "$LAST_SYSTEM_UID" ]; then
				echo -n "Removing $CREATEDUSER system user.."
				deluser --quiet $CREATEDUSER || true
				echo "..done"
			fi
		fi
	fi
fi

 # Remove system group if necessary
CREATEDGROUP="dccgroup"
FIRST_USER_GID=`grep ^FIRST_GID /etc/adduser.conf | cut -f2 -d '='`
if [ -n "$FIRST_USER_GID" ]; then
	if GROUPGID=`getent group $CREATEDGROUP | cut -f 3 -d ':'`; then
		if [ -n "$GROUPGID" ]; then
			if [ "$FIRST_USER_GID" -gt "$GROUPGID" ]; then
				echo -n "Removing $CREATEDGROUP group.."
				delgroup --quiet --only-if-empty $CREATEDGROUP || true
				echo "..done"
			fi
		fi
	fi
fi
	update-rc.d dcc-client remove >/dev/null
fi
exit 0
