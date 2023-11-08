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

# Install QGIS Dependencies
RUN apt-get autoclean
RUN apt-get install -y wget
RUN apt-get --allow-releaseinfo-change update
RUN apt-get install -y gnupg software-properties-common
RUN mkdir -m755 -p /etc/apt/keyrings
RUN wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key D155B8E6A419C5BE
RUN wget -qO - https://debian.qgis.org/debian/qgis-2021.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import
RUN chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg
RUN add-apt-repository "deb https://qgis.org/debian $(lsb_release -c -s) main"
RUN apt-get update
RUN apt-get install -y qgis python-qgis qgis-plugin-grass

# Add python path variables
RUN export PYTHONPATH=/usr/share/qgis/python
RUN export LD_LIBRARY_PATH=/usr/lib

# Additional dependencies
RUN apt-get install -y xvfb
RUN Xvfb :99 -ac -noreset &
RUN export DISPLAY=:99

# Install webapp
WORKDIR /oct
RUN mkdir -p data_from_browser
COPY package*.json ./webapp/
RUN cd webapp && npm ci
COPY . webapp

WORKDIR /oct/webapp
CMD node app.js
