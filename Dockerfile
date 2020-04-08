# Pull base system
FROM debian:buster

# Install utilities
RUN apt-get update
RUN apt-get install -y curl unzip procps bc inotify-tools openjdk-11-jre

WORKDIR /usr/share

# Install GeoServer
ARG VERSION=2.16.2
RUN curl -o geoserver.zip https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/${VERSION}/geoserver-${VERSION}-bin.zip
RUN unzip -q geoserver.zip
RUN mv geoserver-${VERSION} geoserver
RUN rm geoserver.zip
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/root/cityapp/geoserver_data

# Install GRASS GIS and Gnuplot
RUN apt-get install -y grass gnuplot

# Install Node.js
RUN curl -L https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# Clean up
RUN apt-get clean

WORKDIR /root/cityapp

RUN mkdir data_from_browser
RUN mkdir data_to_client

# Install webapp
COPY webapp/package*.json ./webapp/
RUN cd webapp && npm i --only=production --ignore-scripts
COPY webapp/public ./webapp/public
COPY webapp/views ./webapp/views
COPY webapp/app.js ./webapp/
COPY webapp/.env ./webapp/

# Install scripts
COPY scripts ./scripts
COPY run.sh ./

# Start scripts
CMD [ "bash", "run.sh" ]
