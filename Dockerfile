# Pull base system
FROM debian:buster

# Install utilities
RUN apt-get update
RUN apt-get install -y curl unzip

# Install GeoServer
WORKDIR /usr/share
RUN curl -o geoserver.zip https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/2.16.2/geoserver-2.16.2-bin.zip
RUN unzip geoserver.zip
RUN mv geoserver-2.16.2 geoserver
RUN rm geoserver.zip
ENV GEOSERVER_HOME=/usr/share/geoserver

# Install GRASS GIS
RUN apt-get install -y grass

# Install Gnuplot
RUN apt-get install -y gnuplot

# Install Node.js
RUN curl -L https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

# Install other required packages
RUN apt-get install -y procps inotify-tools default-jre
RUN apt-get clean

# Copy the app
WORKDIR /root/cityapp
RUN mkdir data_from_browser
RUN mkdir data_to_client
RUN mkdir geoserver_data
RUN mkdir -p grass/global
RUN mkdir -p grass/skel
RUN mkdir webapp
COPY grass/skel_permanent ./grass/skel_permanent
COPY scripts ./scripts
COPY webapp/public ./webapp/public
COPY webapp/views ./webapp/views
COPY webapp/app.js ./webapp/
COPY webapp/package*.json ./webapp/
COPY webapp/.env ./webapp/
COPY run.sh ./

# Link the GeoServer data directory
RUN rm -r /usr/share/geoserver/data_dir/data
RUN ln -s /root/cityapp/geoserver_data /usr/share/geoserver/data_dir/data

# Install webapp
WORKDIR /root/cityapp/webapp
RUN npm i --only=production

WORKDIR /root/cityapp

EXPOSE 3000
EXPOSE 8080

CMD [ "bash", "run.sh" ]
