# Pull base system
FROM debian:buster

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV GEOSERVER_DATA_DIR=/usr/share/geoserver/data_dir

# Install utilities
RUN apt-get update
RUN apt-get install -y locales curl grass-core enscript ghostscript

# Install locale
RUN sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && locale-gen

# Install Node.js
RUN curl -L https://deb.nodesource.com/setup_15.x | bash -
RUN apt-get install -y nodejs
RUN apt-get clean

# Install webapp
WORKDIR /oct
RUN mkdir -p data_from_browser
COPY package*.json ./webapp/
RUN cd webapp && npm ci
COPY . webapp

WORKDIR /oct/webapp
CMD node app.js

# Install QGIS Dependencies
RUN apt-get install wget
RUN apt-get install -y gnupg software-properties-common
RUN wget -qO - https://qgis.org/downloads/qgis-2020.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import
RUN chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg
RUN add-apt-repository "deb https://qgis.org/ubuntu $(lsb_release -c -s) main"
RUN apt-get update
RUN apt-get install -y qgis qgis-plugin-grass

# Add python path variables
RUN export PYTHONPATH=/usr/share/qgis/python
RUN export LD_LIBRARY_PATH=/usr/lib






