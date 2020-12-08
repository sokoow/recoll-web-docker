FROM ubuntu:18.04 AS builder
WORKDIR /opt/source
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential bison \
autogen automake autoconf libtool  gettext libchm-dev libxapian-dev libxslt-dev aspell-pl \
pkg-config libz-dev python3-pip \
python python-all-dev python3-all-dev \
autotools-dev dh-make debhelper devscripts fakeroot \
xutils lintian pbuilder mc libaspell-dev python-setuptools wget
COPY recoll_1.27.12.orig.tar.gz /opt/source
RUN tar xzvf recoll_1.27.12.orig.tar.gz
COPY debian /opt/source/recoll-1.27.12/debian
WORKDIR /opt/source/recoll-1.27.12
RUN dpkg-buildpackage -rfakeroot

FROM ubuntu:18.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3 libchm1 libxapian30 \
libxml2 libxslt1.1 python aspell-pl aspell-en git poppler-utils python3-pip python-pip antiword unrtf
RUN pip3 install waitress ujson epub
RUN pip install epub
RUN mkdir -p /opt/documents
RUN mkdir -p /opt/xapiandb
COPY --from=builder /opt/source /tmp/recoll-packages
WORKDIR /tmp/recoll-packages
RUN dpkg -i ./recollcmd_1.27.12-1~ppa1~bionic1_amd64.deb
RUN dpkg -i ./python3-recoll_1.27.12-1~ppa1~bionic1_amd64.deb
RUN dpkg -i ./python-recoll_1.27.12-1~ppa1~bionic1_amd64.deb
COPY recoll.conf /root/.recoll/
WORKDIR /opt
RUN git clone https://framagit.org/medoc92/recollwebui.git
ENV S6_SERVICES_GRACETIME=60000
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.1.0.2/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
COPY etc /etc/
ENTRYPOINT ["/init"]
