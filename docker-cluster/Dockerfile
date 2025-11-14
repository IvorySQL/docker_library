FROM redhat/ubi8:latest as builder

ARG MAJOR_VERSION="5"
ARG FULL_VERSION="5.0"

# explicitly set user/group IDs
RUN groupadd -g 1000 ivorysql; \
                useradd -u 1000 -g ivorysql -d /var/local/ivorysql -s /bin/sh ivorysql; \
        mkdir -p /var/local/ivorysql; \
        mkdir -p /usr/src/ivorysql; \
        mkdir -p /var/lib/ivorysql; \
        chown -R ivorysql:ivorysql /var/local/ivorysql; \
        chown -R ivorysql:ivorysql /usr/src/ivorysql; \
        chown -R ivorysql:ivorysql /var/lib/ivorysql

RUN mkdir /docker-entrypoint-initdb.d
# install ivorysql
ENV IVORY_MAJOR $MAJOR_VERSION
ENV IVORY_VERSION $FULL_VERSION

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo; \
    sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

RUN mkdir -p /usr/src/ivorysql; \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
    dnf install -y epel-release;\
    dnf install -y \
    make \
    readline-devel \
    zlib-devel \
    openssl-devel \
    flex \
    wget \
    dpkg; \
    dnf groupinstall -y "Development Tools";\
    dnf install -y \
    llvm-toolset llvm-devel lz4 lz4-devel lz4-libs clang-devel \
    krb5-devel libselinux-devel libxml2-devel cyrus-sasl-gssapi \
    libicu-devel e2fsprogs-devel selinux-policy systemd-devel \
    libxslt-devel openldap-devel openssl-devel pam-devel \
    libuuid-devel python3-devel readline-devel tcl-devel zlib-devel \
    perl perl-devel perl-ExtUtils-Embed;\
    dnf install -y --enablerepo=*ower*ools perl-IPC-Run perl-Time-HiRes perl-Test-Simple uuid-devel;\
    wget -O ivorysql.tar.gz "https://github.com/IvorySQL/IvorySQL/archive/refs/tags/IvorySQL_$IVORY_VERSION.tar.gz"; \
    tar \
            --extract \
                --file ivorysql.tar.gz \
                --directory /usr/src/ivorysql \
                --strip-components 1 \
        ; \
    rm ivorysql.tar.gz; \
    cd /usr/src/ivorysql; \
    wget https://repo.almalinux.org/almalinux/8/PowerTools/$(arch)/os/Packages/bison-devel-3.0.4-10.el8.$(arch).rpm; \
    dnf install -y bison-devel-3.0.4-10.el8.$(arch).rpm; \
    wget https://repo.almalinux.org/almalinux/8/AppStream/$(arch)/os/Packages/bison-3.0.4-10.el8.$(arch).rpm; \
    dnf install -y bison-3.0.4-10.el8.$(arch).rpm; \
    ./configure \
            --prefix=/var/local/ivorysql/ivorysql-$IVORY_MAJOR \
            --enable-cassert --enable-debug --enable-rpath --with-tcl \
            --with-python --with-gssapi --with-pam --with-ldap \
            --with-openssl --with-libedit-preferred --with-uuid=e2fs \
            --with-ossp-uuid  --with-libxml --with-libxslt  --with-perl \
            --with-icu \
    ; \
    make && make install; \
    rm -rf \
                /usr/src/ivorysql \
                /usr/local/share/doc \
                /usr/local/share/man

FROM redhat/ubi8:latest

ARG MAJOR_VERSION="5"
ARG FULL_VERSION="5.0"

RUN groupadd -g 1000 ivorysql; \
                useradd -u 1000 -g ivorysql -d /var/local/ivorysql -s /bin/sh ivorysql;

COPY --from=builder --chown=ivorysql:ivorysql /var/local/ivorysql /var/local/ivorysql/

ENV IVORY_MAJOR $MAJOR_VERSION
ENV IVORY_VERSION $FULL_VERSION

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo; \
    sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
    dnf install -y lz4 lz4-devel lz4-libs krb5-devel libxslt-devel libicu-devel; \
    dnf install -y e2fsprogs-devel libuuid-devel;\
    dnf install -y --enablerepo=*ower*ools uuid-devel;\
    dnf -y clean all

#install patroni 4.0.6
env PATRONI_VER 4.0.6

RUN dnf -y install --nodocs \
                --setopt=skip_missing_names_on_install=False \
                python3-pip \
                python3-psutil \
                python3-psycopg2 \
        && dnf -y clean all

RUN pip3 install --upgrade python-dateutil \
        && pip3 install patroni[etcd]=="${PATRONI_VER}"

ENV PGDATA /var/local/ivorysql/ivorysql-$IVORY_MAJOR/data
ENV PATRONICONF /var/local/ivorysql/ivorysql-$IVORY_MAJOR/patroni
# this 1777 will be replaced by 0700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R ivorysql:ivorysql "$PGDATA" && chmod 750 "$PGDATA"
RUN mkdir -p "$PATRONICONF" && chown -R ivorysql:ivorysql "$PATRONICONF" && chmod 1777 "$PATRONICONF"

COPY docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh

VOLUME $PGDATA $PATRONICONF

ENV PATH $PATH:/var/local/ivorysql/ivorysql-$IVORY_MAJOR/bin

EXPOSE 5432 5866 1521

USER ivorysql

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]
