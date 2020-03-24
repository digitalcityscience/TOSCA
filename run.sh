#!/bin/bash

/usr/share/geoserver/bin/startup.sh & \
	scripts/base/ca_starter.sh & \
	cd webapp; node app.js
