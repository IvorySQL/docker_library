#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM redhat/ubi8:latest as builder

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

ENV IVORY_MAJOR 3
ENV IVORY_VERSION 3.4

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

RUN chown -R ivorysql:ivorysql /var/local/ivorysql/ivorysql-$IVORY_MAJOR
RUN ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        x86_64)  ARCH='amd64' ;; \
        aarch64) ARCH='arm64' ;; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.11/gosu-${ARCH}"; \
    chmod +x /usr/local/bin/gosu

FROM redhat/ubi8:latest

COPY --from=builder /var/local/ivorysql /var/local/ivorysql/
COPY --from=builder /usr/local/bin/gosu /usr/local/bin/gosu

ENV IVORY_MAJOR 3
ENV IVORY_VERSION 3.4

RUN mkdir /docker-entrypoint-initdb.d

RUN useradd -u 1000 ivorysql

RUN dnf install -y \
    lz4 lz4-devel lz4-libs krb5-devel libxslt-devel libicu-devel && dnf -y clean all 

RUN chown -R ivorysql:ivorysql /var/local/ivorysql
RUN chown -R ivorysql:ivorysql /usr/local/bin

ENV PGDATA /var/local/ivorysql/ivorysql-$IVORY_MAJOR/data
# this 1777 will be replaced by 0700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R ivorysql:ivorysql "$PGDATA" && chmod 1777 "$PGDATA"
RUN mkdir -p /var/run/postgresql && chown -R ivorysql:ivorysql /var/run/postgresql && chmod 3777 /var/run/postgresql

VOLUME $PGDATA

ENV PATH $PATH:/var/local/ivorysql/ivorysql-$IVORY_MAJOR/bin

COPY docker-entrypoint.sh docker-ensure-initdb.sh /usr/local/bin/
RUN ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE 5432 5866 1521

CMD ["postgres"]
