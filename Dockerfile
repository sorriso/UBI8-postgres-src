# docker pull registry.access.redhat.com/ubi8/python-39:1-24
# docker pull registry.access.redhat.com/ubi8/openjdk-11-runtime:1.10-10.1638383033
# docker pull registry.access.redhat.com/ubi8/ubi-minimal:8.5-218

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.5-218

###########################################################
#
# LABEL Mandatory for the Pipeline - DO NOT DELETE
#
###########################################################

LABEL name=postgres_community \
      authors=sorriso \
      version=v0.01

###########################################################
#
# ENV Mandatory for the Pipeline - DO NOT DELETE
#
###########################################################

USER 0

###########################################################
#
# Custom ENV configuration
#
###########################################################

ENV PG_VERSION=13.5
ENV GOSU_VERSION=1.14
ENV NSS_WRAPPER_VERSION=1.1.11
ENV HOME=/var/lib/postgresql
ENV PGUSER=postgres
ENV PGGROUP=postgres

###########################################################
#
# Copy Prerequisites data
#
###########################################################

COPY /repo/ubi.repo  /etc/yum.repos.d/ubi.repo
COPY /repo/centos-8.repo /etc/yum.repos.d/centos-8.repo
COPY /gpg /etc/pki/rpm-gpg
COPY /iron-scripts/ /iron-scripts/

###########################################################
#
# Copy application data & set application ENV
#
###########################################################

ENV LANG en_US.utf8
ENV LC_ALL en_US.UTF-8
ENV PATH=$PATH:/opt/postgres/bin/
ENV APP_DATA=${HOME}/data/
ENV PG_SRC_URL=https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz
ENV NSS_SRC_URL=https://ftp.samba.org/pub/cwrap/nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz
ENV GITHUB_RELEASE_URL=https://github.com

COPY /config/postgresql.conf /config/postgresql.conf
COPY /cert/server.* /cert/
COPY /cert/rootCA.pem /usr/share/pki/ca-trust-source/anchors
COPY /scripts/docker-entrypoint.sh /usr/local/bin/

###########################################################
#
# Prerequisites installation
#
###########################################################
RUN set -ex \

    &&  microdnf repolist --disableplugin=subscription-manager \
    &&  microdnf upgrade --disableplugin=subscription-manager -y \

    &&  microdnf install -y  --disableplugin=subscription-manager \
        gzip \
        tar \
        gcc \
        make \
        cmake \
        cmake-data \
        gettext \
        zlib-devel \
        readline-devel \
        glibc-langpack-en \
        fontconfig \
        glibc-locale-source \
        openssl-devel \
        gnupg \
        dirmngr \
        xz-devel \
        findutils \
        bind-utils \
        procps-ng \
        shadow-utils \
        ca-certificates \
    &&  microdnf clean all --disableplugin=subscription-manager \

    && update-ca-trust \

    && curl -L ${GITHUB_RELEASE_URL}/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /sbin/gosu \
    && curl -L ${GITHUB_RELEASE_URL}/tianon/gosu/releases/download/${GOSU_VERSION}/su-amd64.asc -o /sbin/gosu.asc \
    && chmod +x /sbin/gosu \
    && gosu --version \
    && gosu nobody true \

    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /sbin/gosu.asc /sbin/gosu  \
    && command -v gpgconf && gpgconf --kill all || : \
    && rm -rf "$GNUPGHOME" /sbin/gosu.asc \

    && curl -L ${PG_SRC_URL}  -o /postgresql-${PG_VERSION}.tar.gz \
    && curl -L ${PG_SRC_URL}.sha256  -o /postgresql-${PG_VERSION}.tar.gz.sha256 \

    && myfilechecksum=$(sha256sum postgresql-${PG_VERSION}.tar.gz) \
    && mychecksumtofind=$(cat /postgresql-${PG_VERSION}.tar.gz.sha256) \

    && if [[ "${myfilechecksum}" != "${mychecksumtofind}" ]] ; then echo "checksum failed" ; exit 1 ; fi  \

    && tar -xvf /postgresql-${PG_VERSION}.tar.gz \
    && rm /postgresql-${PG_VERSION}.tar.gz \
    && rm /postgresql-${PG_VERSION}.tar.gz.sha256 \

    && localedef -i en_US -f UTF-8 en_US.UTF-8 \

    && mkdir -p /config /cert \

    && curl ${NSS_SRC_URL} -o nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz \
    && curl ${NSS_SRC_URL}.asc -o nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz.asc \

    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz.asc /nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz \
    && command -v gpgconf && gpgconf --kill all || : \
    && rm -rf "$GNUPGHOME" /nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz.asc \

    && mkdir -p /usr/src/nss_wrapper \
    && tar -xzf /nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz -C /usr/src/nss_wrapper --strip-components=1 \
    && rm /nss_wrapper-${NSS_WRAPPER_VERSION}.tar.gz \
    && cd /usr/src/nss_wrapper/ \
    && ls -al \
    && mkdir -p build/ \
    && cd build/ \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/ -DLIB_SUFFIX=64 -S /usr/src/nss_wrapper/ -B /usr/src/nss_wrapper/build/ \
    && make \
    && make install \
    && rm -rf /usr/src/nss_wrapper/ \

###########################################################
#
# Application installation
#
###########################################################

    && export PYTHONDONTWRITEBYTECODE=1 \
    && mkdir /opt/postgres/ \
    && cd /postgresql-${PG_VERSION} \
    && ./configure --prefix=/opt/postgres \
              --enable-integer-datetimes \
              --enable-thread-safety \
              --with-pgport=5432 \
              --with-openssl \
    && make -j 4 all  \
    && make \
    && make install \
    && postgres -V \

    && rm -rf /postgresql-${PG_VERSION} \

    && groupadd -r ${PGUSER} \
    && useradd -r -g ${PGGROUP} --home-dir=${HOME} --shell=/bin/bash ${PGUSER} \
    && usermod -a -G root ${PGUSER} \

    && mkdir -p ${HOME} \
    && chown -R ${PGUSER}:${PGGROUP} ${HOME}\
    && chmod 775 ${HOME} \

    && mkdir /docker-entrypoint-initdb.d \

    && mkdir -p /var/run/postgresql \
    && chown -R ${PGUSER}:${PGGROUP} /var/run/postgresql \
    && chmod 775 /var/run/postgresql \

    && chown -R ${PGUSER}:${PGGROUP} /cert/ \
    && chmod 0600 /cert/server.key \

    && chmod +x /usr/local/bin/docker-entrypoint.sh \

    && chown -R ${PGUSER}:${PGGROUP} "/config" \
    && chmod -R 775 "/config" \

    && chown -R ${PGUSER}:${PGGROUP} "${HOME}" \
    && chmod -R 775 "${HOME}" \

    && mkdir -p "$APP_DATA" \
    && chown -R ${PGUSER}:${PGGROUP} "$APP_DATA" \
    && chmod -R 777 "$APP_DATA" \

###########################################################
#
# hardening / security check
#
###########################################################

# to be done -> iron scripts

###########################################################
#
# cleanup / remove pkg
#
###########################################################

    &&  microdnf remove -y --disableplugin=subscription-manager \
            shadow-utils \
            procps-ng \
            bind-utils \
            findutils \
            xz-devel \
            dirmngr \
            gnupg \
            openssl-devel \
            glibc-locale-source \
            fontconfig \
            glibc-langpack-en \
            readline-devel \
            zlib-devel \
            gettext \
            cmake \
            cmake-data \
            make \
            gcc \
            tar \
            gzip \
            ca-certificates \
    &&  microdnf clean all --disableplugin=subscription-manager \
    && rm -rf /iron-scripts/

###########################################################
#
# Docker image configuration
#
###########################################################

USER postgres

VOLUME /var/lib/postgresql/data

ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE 5432

CMD ["postgres", "-c", "config_file=/config/postgresql.conf"]
