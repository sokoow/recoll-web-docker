FROM ubuntu:22.04 AS builder

WORKDIR /opt/source
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential bison \
autogen automake autoconf libtool  gettext libchm-dev libxapian-dev libxslt-dev aspell-pl \
pkg-config libz-dev python3-pip python3-all-dev python-all-dev \
autotools-dev dh-make debhelper devscripts fakeroot \
xutils lintian pbuilder mc libaspell-dev python3-setuptools python-setuptools wget apt-utils \
dh-python libmagic-dev meson ninja-build libmagic1 vim

# Install QT libraries
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libqt5webkit5-dev libx11-dev pkgconf qt6-base-dev qt6-l10n-tools qt6-webengine-dev

COPY recoll_1.39.0.orig.tar.gz /opt/source
RUN tar xvzf recoll_1.39.0.orig.tar.gz

# extract Debian build instructions from debian source
## COPY recoll_1.39.0-1.debian.tar.xz /opt/source/
## RUN tar xvJf recoll_1.39.0-1.debian.tar.xz -C /opt/source/recoll-1.39.0
# OR copy build instructions directly
COPY debian /opt/source/recoll-1.39.0/debian
WORKDIR /opt/source/recoll-1.39.0
RUN dpkg-buildpackage -rfakeroot


FROM ubuntu:22.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3 libchm1 libxapian30 \
libxml2 libxslt1.1 aspell-pl aspell-en git poppler-utils python3-pip
# Install recoll helpers for extended filetype support
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y unzip xsltproc \
unrar python3-rarfile exiftool \
poppler-utils antiword wv libwpd-tools catdoc libchm-bin info tar librdf-icalendar-perl \
unrtf untex dvi2ps libimage-exiftool-perl python3-chardet python3-midiutil libmagic1
RUN pip3 install waitress ujson epub
RUN pip install epub
RUN mkdir -p /opt/documents
RUN mkdir -p /opt/xapiandb
COPY --from=builder /opt/source /tmp/recoll-packages
WORKDIR /tmp/recoll-packages
RUN dpkg -i ./librecoll39_1.39.0-1_amd64.deb
RUN dpkg -i ./recollcmd_1.39.0-1_amd64.deb
RUN dpkg -i ./python3-recoll_1.39.0-1_amd64.deb
COPY recoll.conf /root/.recoll/
WORKDIR /opt
RUN git clone https://framagit.org/medoc92/recollwebui.git
ENV S6_SERVICES_GRACETIME=60000
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
COPY etc /etc/
ENTRYPOINT ["/init"]
