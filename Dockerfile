FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballs, thelamer"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

# add repo and install qbitorrent
RUN \
 echo "***** add qbitorrent repositories ****" && \
 apt-get update && \
 apt-get install -y \
	gnupg \
	python \
	python3 && \
 curl -s https://bintray.com/user/downloadSubjectPublicKey?username=fedarovich | apt-key add - && \
 apt-key adv --keyserver hkp://keyserver.ubuntu.com:11371 --recv-keys 7CA69FC4 && \
 echo "deb http://ppa.launchpad.net/qbittorrent-team/qbittorrent-stable/ubuntu bionic main" >> /etc/apt/sources.list.d/qbitorrent.list && \
 echo "deb-src http://ppa.launchpad.net/qbittorrent-team/qbittorrent-stable/ubuntu bionic main" >> /etc/apt/sources.list.d/qbitorrent.list && \
 echo "deb https://dl.bintray.com/fedarovich/qbittorrent-cli-debian bionic main" >> /etc/apt/sources.list.d/qbitorrent.list && \
 echo "**** install packages ****" && \
 if [ -z ${QBITTORRENT_VERSION+x} ]; then \
	QBITTORRENT_VERSION=$(curl -sX GET http://ppa.launchpad.net/qbittorrent-team/qbittorrent-stable/ubuntu/dists/bionic/main/binary-amd64/Packages.gz | gunzip -c \
	|grep -A 7 -m 1 "Package: qbittorrent-nox" | awk -F ": " '/Version/{print $2;exit}');\
 fi && \
 apt-get update && \
 apt-get install -y \
	p7zip-full \
	qbittorrent-cli \
	qbittorrent-nox=${QBITTORRENT_VERSION} \
	unrar \
	geoip-bin \
	unzip && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 6881 6881/udp 8080
VOLUME /config /downloads

/bin/sh -c apk add --no-cache         jq=1.6-r0     && curl -J -L -o /tmp/bashio.tar.gz         "https://github.com/hassio-addons/bashio/archive/v0.8.0.tar.gz"     && mkdir /tmp/bashio     && tar zxvf         /tmp/bashio.tar.gz         --strip 1 -C /tmp/bashio         && mv /tmp/bashio/lib /usr/lib/bashio     && ln -s /usr/lib/bashio/bashio /usr/bin/bashio         && rm -f -r         /tmp/*
/bin/sh -c sed -i "s|/config|/config/qbittorrent|g" /etc/services.d/qbittorrent/run     && sed -i "s|/config|/config/qbittorrent|g" /etc/cont-init.d/30-config     && sed -i "s|/downloads|/share/downloads|g" /etc/cont-init.d/30-config     && sed -i "s|/downloads|/share/downloads|g" /app/qbittorrent/share/qbittorrent/qbittorrent.conf
LABEL io.hass.arch=amd64
LABEL io.hass.type=addon
LABEL io.hass.name=qbittorrent
