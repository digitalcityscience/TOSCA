# Open City Toolkit

## Requirements

The Open City Toolkit is a framework connecting several external tools in order to implement a flexible and easy-to-use web GIS solution. A Linux system equipped with several applications is required as a base system:

1. GeoServer
1. GRASS GIS
1. enscript + ghostscript
1. Node.js

The following instructions provide guidance for the installation of all required components.

## Installation

### With Docker

You can quickly set up a running system via [Docker](https://docs.docker.com/).

Before building the image, environment variables need to be set in `webapp/.env`:
- `GEOSERVER_URL`: The base URL of the local GeoServer instance. This should normally be the public IP or domain of the server, port 8080.
- `INITIAL_LAT`, `INITIAL_LON`: Initial center coordinates for the map view.

It is also required to create these directories:
```
mkdir -p geoserver_data_dir/data
mkdir -p grass/global
mkdir grass/metadata
touch grass/metadata/metadata.json
mkdir output
```

Build the Docker image:
```
docker build -t oct .
```

Start a container using the newly created image.
```
docker run -dti -v `pwd`/geoserver_data_dir:/usr/share/geoserver/data_dir -v `pwd`/grass:/oct/grass -v `pwd`/output:/oct/output -p 3000:3000 -p 8080:8080 --name my_oct oct
```

If you want to override any environment variables, you can do so using the `-e` option:
```
docker run -dti -e GEOSERVER_URL=... -e INITIAL_LAT=... -e INITIAL_LON=... -v `pwd`/geoserver_data_dir:/usr/share/geoserver/data_dir -v `pwd`/grass:/oct/grass -v `pwd`/output:/oct/output -p 3000:3000 -p 8080:8080 --name my_oct oct
```

The `geoserver_data`, `grass` and `output` directories are mounted into the container as volumes in order to make their contents persistent and accessible from the host system.

While the container is running, the app is served at http://localhost:3000 and GeoServer is available at http://localhost:8080/geoserver/.

### Without Docker

#### Operating system

A Linux system is required. Any modern and up-to-date Linux environment can be used, however, these instructions are valid for a Debian Stable system.

#### Installation directory

It is recommended to install the app into a home directory of a dedicated user created for this purpose (e.g., `oct_user`). Here it is assumed that the dedicated user’s home directory is `/home/oct_user`.

#### External components

##### GeoServer

Use a current stable version of GeoServer. While you can install GeoServer in an arbitrary location, it is recommended to install it in `/usr/share/geoserver`.

Download a platform-independent binary of GeoServer (e.g., `geoserver-2.17.2-bin.zip`) from geoserver.org.

Create the directory:
```
mkdir /usr/share/geoserver
```

Move the zipped GeoServer to this new directory and unzip it:
```
mv geoserver-2.17.2-bin.zip /usr/share/geoserver
cd /usr/share/geoserver
unzip ./geoserver-2.17.2-bin.zip
```

Geoserver is now ready to run: the startup and shutdown scripts are located in `/usr/share/geoserver/bin/`), but not yet ready to use with the app. Because stylesheets are in CSS format, it is required to install a CSS extension for GeoServer. Download the extension that matches your GeoServer version, e.g.: https://build.geoserver.org/geoserver/2.17.x/ext-latest/geoserver-2.17-SNAPSHOT-css-plugin.zip

Move the downloaded file and unzip it:
```
mv geoserver-2.17-SNAPSHOT-css-plugin.zip /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/
cd /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/
unzip geoserver-2.17-SNAPSHOT-css-plugin.zip
```

After installing Geoserver, it is required to create a symbolic link pointing to `/home/oct_user/oct/geoserver_data`, because GRASS GIS will export the results to that directory.
```
ln -s ~/oct/geoserver_data /usr/share/geoserver/data_dir/data/cityapp
```

Maps generated by OCT require an adequate symbology, stored as “workspace” in GeoServer’s “workspaces” directory. This new symbology is prepared for OCT, therefore it can’t be found in the default installation of Geoserver. The `~/oct/geoserver_workspaces` directory is used to store these settings in subdirectories named `raster` and `vector`. Those are predefined GeoServer workspaces that need to be linked to the workspaces directory of GeoServer.
```
ln -s ~/oct/geoserver_workspaces/raster /usr/share/geoserver/data_dir/workspaces/raster
ln -s ~/oct/geoserver_workspaces/vector /usr/share/geoserver/data_dir/workspaces/vector
```

##### GRASS GIS

GRASS GIS is the core component of the backend: a highly developed, generic-purpose, cross-platform GIS system. It is required to install GRASS GIS version 7.1 or newer. Download GRASS GIS from: https://grass.osgeo.org/ or install it using a package manager:
```
apt-get install grass
```

##### Node.js

The recommended way of installing Node.js in Linux is via [NodeSource](https://github.com/nodesource/distributions) (follow the instructions for your distribution). On a Debian system:
```
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs
```

Now change to the webapp directory and install the dependencies:
```
cd ~/oct/webapp
npm install
```

##### Enscript/Ghostscript

Enscript is a command line tool to convert text files to PostScript, HTML, RTF, ANSI. It is used to create statistical output.
Ghostscript is a package containing tools to manage postscript files, including a ps to pdf converter too.
Install both packages:
```
apt-get install enscript ghostscript
```

#### Running the app

Before starting the app, you need to set a few environment variables in the `.env` file:
- `DATA_FROM_BROWSER_DIR`: directory to store temporary messages from the client
- `GRASS_DIR`: directory to store map files
- `OUTPUT_DIR`: directory to store human-readable analysis outputs
- `GEOSERVER_URL`: URL of the GeoServer
- `INITIAL_LAT`: latitude of map view center on startup
- `INITIAL_LON`: longitude of map view center on startup

Now to start the server, run:
```
node app.js
```

Open a browser at http://localhost:3000 and you should be greeted with the app’s interface.

If you use the server in production, it is recommended to use a process manager, such as [pm2](https://pm2.keymetrics.io/). To install pm2, run:
```
npm install -g pm2
```
To start a process for OCT:
```
pm2 start ~/oct/webapp/app.js
```
