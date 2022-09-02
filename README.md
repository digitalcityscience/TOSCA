# Toolkit for Open and Sustainable City Planning and Analysis
Welcome to the Toolkit for Open and Sustainable City Planning and Analysis!

The Toolkit for Open and Sustainable City Planning and Analysis (TOSCA) was developed in cooperation between the Digital City Science of the HafenCity University Hamburg (HCU) and Deutsche Gesellschaft für Internationale Zusammenarbeit GmbH (GIZ) in India and Ecuador. It is an open source tool and the software for this project is based entirely on open source components. TOSCA is a web-based geographic information system (GIS) for multi-touch tables that is optimised for the use by non-GIS-experts. It supports integrated and participatory urban planning processes, fostering dialogue between governments and citizens and exchange of knowledge and data between government departments. The main functionality of the TOSCA is to visualise and analyse complex urban data, jointly among local practitioners and with citizens.

https://user-images.githubusercontent.com/66685611/122094650-af3ef400-ce0c-11eb-91a1-b8b271720a36.mp4

You can also look under the Wiki section to read the [administrator's](https://github.com/digitalcityscience/TOSCA/wiki/2.-Open-City-Toolkit-%E2%80%90-Administrator's-Guide) manual or the [user](https://github.com/digitalcityscience/TOSCA/wiki/1.-Open-City-Toolkit-%E2%80%90-User-manual) manual.


## Requirements

TOSCA is a framework connecting several external tools in order to implement a flexible and easy-to-use web GIS solution. A Linux system equipped with several applications is required as a base system:

1. GeoServer
1. GRASS GIS
1. enscript + ghostscript
1. Node.js

The following instructions provide guidance for the installation of all required components.

## Installation

### With Docker

You can quickly set up a running system via [Docker](https://docs.docker.com/).

To build and start the stack with [Docker Compose](https://docs.docker.com/compose/), first open `docker-compose.yaml` in your root directory and change the **volume directories** to your local absolute paths:

```yaml
...
volumes:
  geoserver_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./geoserver_data_dir # change this to your local absolute path
  grass:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./grass # change this to your local absolute path
  output:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./output # change this to your local absolute path
```

then run this command in your root directory:

```
docker-compose up --build
```

For the webapp it may be required to change some environment variables. These are configured in the `environment` section of the `webapp` service in `docker-compose.yml`.
- `GEOSERVER_URL`: The base URL of the local GeoServer instance. This should normally be the public IP or domain of the server, port 8080.
- `INITIAL_LAT`, `INITIAL_LON`: Initial center coordinates for the map view.
- `USE_LANG`: Language of the user interface (default: English). A matching translations file must exist in `webapp/i18n`.

If Docker Compose is not available, you can also build the GeoServer and webapp containers separately:

```
docker build -t oct-geoserver geoserver

docker build -t oct-webapp webapp
```

Run the containers using the newly created images:

```
docker run -dti \
-v `pwd`/geoserver_data_dir:/usr/share/geoserver/data_dir \
-p 8080:8080 oct-geoserver

docker run -dti \
-e DATA_FROM_BROWSER_DIR=/oct/data_from_browser \
-e GRASS_DIR=/oct/grass \
-e OUTPUT_DIR=/oct/output \
-e GEOSERVER_URL=http://localhost:8080/ \
-v `pwd`/geoserver_data_dir:/usr/share/geoserver/data_dir \
-v `pwd`/grass:/oct/grass \
-v `pwd`/output:/oct/output \
-p 3000:3000 oct-webapp
```

The `geoserver_data`, `grass` and `output` directories are mounted into the container as volumes in order to make their contents persistent and accessible from the host system.

While the stack is running, the app is served at http://localhost:3000 and GeoServer is available at http://localhost:8080/geoserver/.

### Without Docker

#### Operating system

A Linux system is required. Any modern and up-to-date Linux environment can be used, however, these instructions are valid for a Debian Stable system.

#### Installation directory

It is recommended to install the app into a home directory of a dedicated user created for this purpose (e.g., `oct_user`). Here it is assumed that the dedicated user’s home directory is `/home/oct_user`.

Download the contents of this repository to `/home/oct_user/oct`.

#### External components

##### GeoServer

GeoServer requires a Java Runtime Environment. Install the JRE:
```
apt-get install openjdk-11-jre-headless
```

Use a current stable version of GeoServer. Download a platform-independent binary of GeoServer (e.g., `geoserver-2.17.2-bin.zip`) from geoserver.org.

While you can install GeoServer in an arbitrary location, it is recommended to install it in `/usr/share/geoserver`. Create the directory:
```
mkdir /usr/share/geoserver
```

Move the downloaded GeoServer archive to the new directory and unzip it:
```
mv geoserver-2.17.2-bin.zip /usr/share/geoserver
cd /usr/share/geoserver
unzip ./geoserver-2.17.2-bin.zip
```

Because stylesheets are in CSS format, it is required to install a CSS extension for GeoServer. Download the extension that matches your GeoServer version, e.g.: https://build.geoserver.org/geoserver/2.17.x/ext-latest/geoserver-2.17-SNAPSHOT-css-plugin.zip

Move the downloaded file and unzip it:
```
mv geoserver-2.17-SNAPSHOT-css-plugin.zip /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/
cd /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/
unzip geoserver-2.17-SNAPSHOT-css-plugin.zip
```

After installing GeoServer, it is required to create a symbolic link pointing to `/home/oct_user/oct/geoserver_data_dir`, because GRASS GIS will export the results to that directory.
```
rm -r /usr/share/geoserver/data_dir
ln -s /home/oct_user/oct/geoserver_data_dir /usr/share/geoserver/data_dir
```

GeoServer is now ready to run. To start GeoServer, execute:
```
GEOSERVER_HOME=/usr/share/geoserver /usr/share/geoserver/bin/startup.sh
```
To stop it:
```
GEOSERVER_HOME=/usr/share/geoserver /usr/share/geoserver/bin/shutdown.sh
```

##### GRASS GIS

GRASS GIS is the core component of the backend: a highly developed, generic-purpose, cross-platform GIS system. It is required to install GRASS GIS version 7.1 or newer. Download GRASS GIS from: https://grass.osgeo.org/ or install it using a package manager:
```
apt-get install grass-core
```

##### Enscript/Ghostscript

Enscript is a command line tool used to create statistical output.
Ghostscript is a package containing tools to manage PostScript files, including a PS to PDF converter. Install both packages:
```
apt-get install enscript ghostscript
```

##### Node.js

The recommended way of installing Node.js in Linux is via [NodeSource](https://github.com/nodesource/distributions) (follow the instructions for your distribution). On a Debian system:
```
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs
```

Now change to the webapp directory and install the dependencies:
```
cd /home/oct_user/oct/webapp
npm install
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

Open a browser at http://localhost:3000 – you should now see the user interface of the Open City Toolkit.

If you use the server in production, it is recommended to use a process manager, such as [pm2](https://pm2.keymetrics.io/). To install pm2, run:
```
npm install -g pm2
```
To start a process for OCT:
```
pm2 start /home/oct_user/oct/webapp/app.js
```

## Add metadata for map layers

For better user experience, the OCT allows the user to add metadata to map layers.
Once added correctly, the metadata will be queried in various places within in the app, e.g. in the attribute table shown after the user clicks 'show attribute' in the query module.
The metadata should be added in a `metadata.json` file under the `grass/metadata` folder.
The metadata should conform to the following format:

```json
[
  {
    "table": "<map layer name - find out the layer names under the grass/global folder>",
    "description": "<description of the layer>",
    "columns": [
      {
        "column": "<column name - find out the column names by running db.columns command in GRASS>",
        "description": "<description of the column>"
      },
      {
        "column": "",
        "description": ""
      },
    ]
  },
  {
    "table": "",
    "description": "",
    "columns": [
      {
        "column": "",
        "description": ""
      }
    ]
  }
]
```
