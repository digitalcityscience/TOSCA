# Pull base system
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/usr/share/geoserver/data_dir

# Install utilities
RUN apt-get update
RUN apt-get install -y locales curl unzip openjdk-11-jre-headless

# Install locale
RUN sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && locale-gen

# Install GeoServer and CSS plugin
WORKDIR /usr/share/geoserver
RUN curl -L -o geoserver.zip https://sourceforge.net/projects/geoserver/files/GeoServer/2.18.0/geoserver-2.18.0-bin.zip
RUN unzip -q geoserver.zip && rm geoserver.zip
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF/lib
RUN curl -o css-plugin.zip https://build.geoserver.org/geoserver/2.18.x/ext-latest/geoserver-2.18-SNAPSHOT-css-plugin.zip
RUN unzip -q css-plugin.zip && rm css-plugin.zip
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF
RUN sed -i '170d;191d;222d;227d' web.xml

# Clean up
RUN apt-get clean

# Start scripts
CMD /usr/share/geoserver/bin/startup.sh 2>&1