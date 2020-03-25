# Pull base system
FROM debian:buster

# Install utilities
RUN apt-get update
RUN apt-get install -y curl unzip

WORKDIR /usr/share

# Install GeoServer
RUN curl -o geoserver.zip https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/2.16.2/geoserver-2.16.2-bin.zip
RUN unzip geoserver.zip
RUN mv geoserver-2.16.2 geoserver
RUN rm geoserver.zip
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/root/cityapp/geoserver_data

# Install GRASS GIS
RUN apt-get install -y grass

# Install Gnuplot
RUN apt-get install -y gnuplot

# Install Node.js
RUN curl -L https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# Install other required packages
RUN apt-get install -y procps bc inotify-tools openjdk-11-jre
RUN apt-get clean

WORKDIR /root/cityapp

# Configure persistent volumes
VOLUME ./geoserver_data
VOLUME ./grass

# Copy scripts
COPY scripts ./scripts
RUN mkdir data_from_browser
RUN mkdir data_to_client
RUN mkdir webapp

WORKDIR /root/cityapp/webapp

# Install webapp
COPY webapp/public ./public
COPY webapp/views ./views
COPY webapp/app.js ./
COPY webapp/package*.json ./
COPY webapp/.env ./
RUN npm i --only=production

WORKDIR /root/cityapp

# Start scripts
COPY run.sh ./
CMD [ "bash", "run.sh" ]
