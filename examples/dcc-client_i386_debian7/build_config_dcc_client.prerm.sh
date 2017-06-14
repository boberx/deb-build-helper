#!/bin/sh

set -e

if [ -x "/etc/init.d/dcc-client" ]; then
	/etc/init.d/dcc-client stop
	exit 0
fi
