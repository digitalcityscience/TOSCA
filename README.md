# Open City Toolkit

The base idea of the software is relatively simple. There is a frontend communicating to the user and displaying the results as maps, data, and graphs, and a backend, processing calculations, queries, data storage, and serving maps. In between there is a software layer as interface allowing the web-based user interface to communicate with the GIS  backend.

The frontend is a JavaScript-based dashboard, running in a simple web browser (such as Firefox), using the Leaflet library to display various maps.

The backend has two pillars. GeoServer is to serve maps, and GRASS GIS is to process calculations. GRASS GIS map outputs are exported into the GeoServer’s data directory, and GeoServer only serves maps from the GRASS GIS. To make the GRASS calls available to the web client, Node.js is used as an interface layer. Thus, all requests, input data and dialogue messages are managed by the Node.js server.

Data are basically stored in GRASS GIS mapsets, allowing direct access for calculations.

## Quick start

You can quickly set up a running system via [Docker](https://docs.docker.com/) – download the contents of this repository, change to its root directory and build the Docker image:
```
docker build -t cityapp .
```

Now start a container using the newly created image:
```
docker run -ti \
  -v ~/<local path to>/geoserver_data:/usr/share/geoserver/data_dir/data \
  -v ~/<local path to>/grass:/root/cityapp/grass \
  -p 3000:3000 \
  -p 8080:8080 \
  --name cityapp_1 \
  cityapp
```

The app will run on http://localhost:3000, and GeoServer will be available at http://localhost:8080/geoserver/.

The `geoserver_data` and `grass` directories are mounted as volumes into the container, in order to make their contents persistent.

## 1 System requirements

### 1.1 Operating system

A Linux system is required. Neither the kernel version, nor the flavour has any significance. But, regarding to the web-based approach and server-client architecture, a modern, up-to-date Linux environment is highly recommended.

#### 1.1.1 User permissions

It is highly recommended to install your Cityapp copy into a home directory of a dedicated user created for this purpose. This is a simple user directory without any specific properties. It is only to clearly separate the data stored in the `cityapp` directory and to allow a clear data management through file permissions. In this manual it is expected that the dedicated home directory is `/home/cityapp_user`. Of course, any other name is allowed, it is only an example.

### 1.2 Components

The cityapp system is the frame system only, and it does not contain third-party components or their intallation scripts. Those components have to be installed separately. It is because although our recommendation is a Debian-based Linux, you may select your preferred distribution too.

It is recommended to follow the installation order:
1. GeoServer
2. GRASS GIS
3. Gnuplot
4. Node.js
5. Cityapp

#### 1.2.1 Geoserver

Use a current stable version of GeoServer, at least version 2.15. The expected path of the GeoServer data directory on your system is `/usr/share/geoserver/data_dir/data`, therefore our recommendation is to install GeoServer into `/usr/share/geoserver`.

To install GeoServer, first download the latest stable package from http://geoserver.org/release/stable/.

- select “Platform Independent Binary”
- unzip downloaded file (for example: geoserver-2.16.2-bin.zip) into `/usr/share`. Now you have a new directory named as `/usr/share/geoserver-2.xx` (for example: `/usr/share/geoserver-2.16.2`)
- rename this directory to `/usr/share/geoserver`

#### 1.2.2 GRASS GIS

GRASS GIS is the core component of the backend: a highly developed generic purpose, cross-platform GIS system. It is required to install GRASS GIS version 7.1 or newer. The GRASS GIS installation path has no importance. Download GRASS GIS from: https://grass.osgeo.org/

On a Debian-based system:
```
apt-get install grass
```

For other systems and for further info, please visit: https://grasswiki.osgeo.org/wiki/Installation_Guide

#### 1.2.3 Gnuplot

Gnuplot is used to create various data visualizations and export them into PNG format, allowing the browser to display them. Gnuplot is a default component of most Linux distributions, but if your installed system does not contain it, it can be downloaded from http://www.gnuplot.info/.

On a Debian-based system:
```
apt-get install gnuplot
```

#### 1.2.4 Node.js

Node.js is a crucial component to run the frontend, therefore it has to be installed properly. Version 12 or higher is required. The recommnded way of installing Node.js in Linux is via [NodeSource](https://github.com/nodesource/distributions) (follow the instructions for your distribution).

On a Debian system:
```
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs
```

#### 1.2.5 Cityapp

Extract the contents of this repository into a `cityapp` directory in the Cityapp user’s home, such as `/home/cityapp_user/cityapp`.

This will be the base directory of any further operation.
Now the only thing to do is to create a symlink in the GeoServer’s data directory pointing at `cityapp/geoserver_data`.
- The expected location of geoserver directory is `/usr/share/geoserver/`
- Even if you have a newly installed GeoServer, there is already a data directory: `/usr/share/geoserver/data_dir/data`. First rename this directory to `data_old` (or any arbitrary name).
```
mv /usr/share/geoserver/data_dir/data /usr/share/geoserver/data_dir/data_old
```
- Next create the symbolic link:
```
ln -s /home/cityapp_user/cityapp/geoserver_data /usr/share/geoserver/data_dir/data
```

## 2 Running the app

### 2.1 GIS backend

To start the backend, run:
```
~/cityapp/scripts/base/ca_starter.sh
```

To stop it:
```
~/cityapp/scripts/base/ca_shutdown.sh
```

### 2.2 Web app

First change to the `webapp` directory. Before you start the server for the first time, you must run:
```
npm install
```

Now to start the server, run:
```
node app.js
```

Open a browser at http://localhost:3000 and you should see the app's user interface.

If you want to use the server in production, it is recommended to use the process manager [pm2](https://pm2.keymetrics.io/). To install it, run:
```
sudo npm install -g pm2
```
To start a process for Cityapp:
```
pm2 start ~/cityapp/webapp/app.js --name=cityapp
```
