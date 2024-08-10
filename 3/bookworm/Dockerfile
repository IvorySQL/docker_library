#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# Use Debian  as the base image
FROM debian:bookworm-slim as builder 

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

# Set environment variables for IvorySQL
ENV IVORY_MAJOR 3
ENV IVORY_VERSION 3.3
ARG USE_CHINA_MIRROR=false

# Use China mirror if specified
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
       sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources ;\
    fi

# Update package list and install necessary dependencies
RUN apt-get update
RUN apt-get install -y make \
    libreadline-dev \
    zlib1g-dev \
    libssl-dev \
    flex \
    wget \
    dpkg \
    build-essential \
    llvm \
    llvm-dev \
    liblz4-dev \
    clang \
    libkrb5-dev \
    libselinux1-dev \
    libxml2-dev \
    libsasl2-dev \
    libicu-dev \
    e2fslibs-dev \
    libsepol-dev \
    libsystemd-dev \
    libxslt1-dev \
    libldap2-dev \
    libssl-dev \
    libpam0g-dev \
    uuid-dev \
    python3-dev \
    libreadline-dev \
    tcl-dev \
    zlib1g-dev \
    perl \
    libperl-dev \
    perl \
    perl-base \
    perl-modules \
    perl-doc \
    m4 \
    libc6 \
    libbison-dev\
    libossp-uuid-dev\
    curl 
 
RUN wget https://mirrors.ustc.edu.cn/gnu/bison/bison-3.0.4.tar.gz; \
    tar -xzvf bison-3.0.4.tar.gz; \
    cd bison-3.0.4 ; \
    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c ;\
    echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h ;\
    mkdir build && cd build ;\
    ../configure ;\
    make && make install ;

RUN wget -O ivorysql.tar.gz "https://github.com/IvorySQL/IvorySQL/archive/refs/tags/IvorySQL_$IVORY_VERSION.tar.gz"; \
    tar \
	    --extract \
		--file ivorysql.tar.gz \
		--directory /usr/src/ivorysql \
		--strip-components 1 \
	; \
    rm ivorysql.tar.gz; \
    cd /usr/src/ivorysql; \
    ./configure \
            --prefix=/var/local/ivorysql/ivorysql-$IVORY_MAJOR \
            --enable-cassert --enable-debug --enable-rpath --with-tcl \
            --with-python --with-gssapi --with-pam --with-ldap \
            --with-openssl --with-libedit-preferred --with-uuid=e2fs \
            --with-ossp-uuid  --with-libxml --with-libxslt  --with-perl \
            --without-icu \
    ;\
    make && make install; 
    
RUN rm -rf \
		/usr/src/ivorysql \
		/usr/local/share/doc \
		/usr/local/share/man

RUN chown -R ivorysql:ivorysql /var/local/ivorysql/ivorysql-$IVORY_MAJOR 

RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64"

RUN chmod +x /usr/local/bin/gosu

FROM debian:bookworm-slim

COPY --from=builder /var/local/ivorysql /var/local/ivorysql/
COPY --from=builder /usr/local/bin/gosu /usr/local/bin/gosu

ENV IVORY_MAJOR 3
ENV IVORY_VERSION 3.3
ARG USE_CHINA_MIRROR=false
RUN mkdir /docker-entrypoint-initdb.d

RUN useradd -u 1000 ivorysql

# Use China mirror if specified
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
       sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources ;\
    fi

RUN apt-get update && \
    apt-get install -y \
        liblz4-1 \
        liblz4-dev \
        libkrb5-dev \
        libxslt1-dev \
        libldap-common \
        libldap-2.5-0   \
        libldap2-dev     \
        libreadline-dev \
        libicu-dev && \
    apt-get clean


RUN chown -R ivorysql:ivorysql /var/local/ivorysql
RUN chown -R ivorysql:ivorysql /usr/local/bin

ENV PGDATA /var/local/ivorysql/ivorysql-$IVORY_MAJOR/data

# this 1777 will be replaced by 0700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R ivorysql:ivorysql "$PGDATA" && chmod 1777 "$PGDATA"
RUN mkdir -p /var/run/postgresql && chown -R ivorysql:ivorysql /var/run/postgresql && chmod 3777 /var/run/postgresql

VOLUME ["/var/local/ivorysql/ivorysql-$IVORY_MAJOR/data","/var/local/ivorysql/data"]

ENV PATH $PATH:/var/local/ivorysql/ivorysql-$IVORY_MAJOR/bin

COPY docker-entrypoint.sh docker-ensure-initdb.sh /usr/local/bin/
RUN ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE 5432 5866 1521

CMD ["postgres"]
