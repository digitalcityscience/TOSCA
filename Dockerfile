# Pull base system
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/usr/share/geoserver/data_dir

# Install utilities
RUN apt-get update
RUN apt-get install -y locales curl unzip procps bc inotify-tools openjdk-11-jre-headless

# Install locale
RUN sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && locale-gen

# Install GeoServer and CSS plugin
WORKDIR /usr/share
RUN curl -L -o geoserver.zip https://sourceforge.net/projects/geoserver/files/GeoServer/2.16.2/geoserver-2.16.2-bin.zip
RUN unzip -q geoserver.zip && rm geoserver.zip
RUN mv geoserver-2.16.2 geoserver
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF/lib
RUN curl -o css-plugin.zip https://build.geoserver.org/geoserver/2.16.x/ext-latest/geoserver-2.16-SNAPSHOT-css-plugin.zip
RUN unzip css-plugin.zip && rm css-plugin.zip

# Install GRASS GIS
RUN apt-get install -y grass-core

# Install Gnuplot
RUN apt-get install -y gnuplot-nox

# Install Node.js
RUN curl -L https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# Clean up
RUN apt-get clean

# Install webapp
WORKDIR /root/cityapp
RUN mkdir data_from_browser
RUN mkdir data_to_client
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
