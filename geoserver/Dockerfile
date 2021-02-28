# Pull base system
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/usr/share/geoserver/data_dir

# Install utilities
RUN apt-get update
RUN apt-get install -y curl unzip openjdk-11-jre-headless
RUN apt-get clean

# Install GeoServer and CSS plugin
WORKDIR /usr/share/geoserver
RUN curl -L -o geoserver.zip https://sourceforge.net/projects/geoserver/files/GeoServer/2.18.0/geoserver-2.18.0-bin.zip
RUN unzip -q geoserver.zip && rm geoserver.zip
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF/lib
RUN curl -o css-plugin.zip https://build.geoserver.org/geoserver/2.18.x/ext-latest/geoserver-2.18-SNAPSHOT-css-plugin.zip
RUN unzip -q css-plugin.zip && rm css-plugin.zip
# enable CORS
RUN sed -i '170d;191d;222d;227d' /usr/share/geoserver/webapps/geoserver/WEB-INF/web.xml

CMD /usr/share/geoserver/bin/startup.sh
