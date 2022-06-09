# Pull base system
FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV GEOSERVER_HOME=/usr/share/geoserver
ENV GEOSERVER_DATA_DIR=/usr/share/geoserver/data_dir

# Install utilities
RUN apt-get update
RUN apt-get install -y curl unzip openjdk-11-jre-headless zip
RUN apt-get clean

# Install GeoServer and CSS plugin
WORKDIR /usr/share/geoserver
RUN curl -L -o geoserver.zip https://build.geoserver.org/geoserver/2.18.x/geoserver-2.18.x-latest-bin.zip
RUN unzip -q geoserver.zip && rm geoserver.zip
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF/lib
RUN curl -o css-plugin.zip https://build.geoserver.org/geoserver/2.18.x/ext-latest/geoserver-2.18-SNAPSHOT-css-plugin.zip
RUN unzip -q css-plugin.zip && rm css-plugin.zip

RUN curl -o geostyler-plugin.zip https://build.geoserver.org/geoserver/2.18.x/community-latest/geoserver-2.18-SNAPSHOT-geostyler-plugin.zip
RUN unzip -q geostyler-plugin.zip && rm geostyler-plugin.zip
RUN unzip -d geostyler -q gs-geostyler-2.18-SNAPSHOT.jar && rm gs-geostyler-2.18-SNAPSHOT.jar
RUN sed -i '0,/absolute/s//fixed/' /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/geostyler/org/geoserver/wms/web/data/js/geostyler.css
WORKDIR /usr/share/geoserver/webapps/geoserver/WEB-INF/lib/geostyler
RUN zip -q -r gs-geostyler-2.18-SNAPSHOT.jar .
RUN mv gs-geostyler-2.18-SNAPSHOT.jar /usr/share/geoserver/webapps/geoserver/WEB-INF/lib

# enable CORS
RUN sed -i '170d;191d;222d;227d' /usr/share/geoserver/webapps/geoserver/WEB-INF/web.xml

CMD /usr/share/geoserver/bin/startup.sh
