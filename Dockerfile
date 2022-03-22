FROM ubuntu:20.04
LABEL PAULO CORREA<p.correa@comforte.com>

ENV DEBIAN_FRONTEND=noninteractive

ARG JAR_FILE

ENV _JAVA_OPTIONS "-Xms256m -Xmx512m -Djava.awt.headless=true"

ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -y && apt-get install -y wget gnupg2 curl python2.7 libgconf-2-4

# Set up the Chrome PPA
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
# Update the package list and install chrome
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y unzip openjdk-11-jdk nano

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle

RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && groupadd --system --gid 1000 gradle \
    && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln -s /home/gradle/.gradle /root/.gradle

# Create Gradle volume
VOLUME "/home/gradle/.gradle"

WORKDIR /home/gradle

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        fontconfig \
        unzip \
        \
        bzr \
        git \        
        openssh-client \        
    && rm -rf /var/lib/apt/lists/*

ARG GRADLE_VERSION=6.9.2
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" \
    && echo "I=nstalling Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-$GRADLE_VERSION" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Testing Gradle installation" \
    && gradle --version

WORKDIR /

RUN apt-get update && apt-get install -y apt-utils xdg-utils fonts-liberation libcairo2 libgbm1 libgtk-3-0 libpango-1.0-0 libxdamage1 libxkbcommon0 libu2f-udev xvfb libgtk2.0-0 libxtst6 libxss1 libgconf-2-4 libnss3 libasound2 

# Setup Firefox and the fonts
RUN \
apt-get update && \
apt-get install -y \
firefox \
ca-certificates \
imagemagick \
upx \
xfonts-100dpi \
xfonts-75dpi \
xfonts-scalable \
xfonts-cyrillic \
xvfb \
libxtst6 \
cabextract \
dbus-x11 \
openssl \
--no-install-recommends && \
apt-get clean autoclean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
upx --best /usr/lib/firefox/firefox 

# Solvin the link of the latest library https://github.com/marcellodesales/gradle-java-docker/blob/master/Dockerfile#L25
RUN \
mkdir -p /usr/lib/mozilla/plugins && \
ln -s /opt/java/jre/lib/amd64/libnpjp2.so /usr/lib/mozilla/plugins


USER root

#=========
# Firefox
#=========
ARG FIREFOX_VERSION=98.0.1
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install firefox \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
  && wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2 \
  && apt-get -y purge firefox \
  && rm -rf /opt/firefox \
  && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
  && rm /tmp/firefox.tar.bz2 \
  && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
  && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox

#============
# GeckoDriver
#============
ARG GECKODRIVER_VERSION=v0.30.0
RUN wget --no-verbose https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux32.tar.gz \
  && rm -rf /opt/geckodriver \
  && tar -C /opt -zxf geckodriver-$GECKODRIVER_VERSION-linux32.tar.gz \
  && chmod 755 /opt/geckodriver \
  && ln -fs /opt/geckodriver /usr/bin/geckodriver

RUN curl -fsSL https://get.docker.com -o get-docker.sh 
RUN DRY_RUN=1 sh ./get-docker.sh