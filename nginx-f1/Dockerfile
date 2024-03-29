FROM ubuntu:20.04

ARG MAKE_J=4
ARG NGINX_VERSION=1.19.7
ARG PAGESPEED_VERSION=1.13.35.2
ARG LIBPNG_VERSION=1.6.37

ENV MAKE_J=${MAKE_J} \
	NGINX_VERSION=${NGINX_VERSION} \
	LIBPNG_VERSION=${LIBPNG_VERSION} \
	PAGESPEED_VERSION=${PAGESPEED_VERSION} \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
	apt-get upgrade -y

RUN apt-get install -y \
	apt-utils \
	git nano \
	g++ \
	gcc \
	curl \
	make \
	unzip \
	bzip2 \
	gperf \
	python \
	openssl \
	libuuid1 \
	apt-utils \
	pkg-config \
	icu-devtools \
	build-essential \
	ca-certificates \
	uuid-dev \
	zlib1g-dev \
	libicu-dev \
	libssl-dev \
	apache2-dev \
	libpcre3 \
	libpcre3-dev \
	libmaxminddb-dev \
	libpng-dev \
	libaprutil1-dev \
	libturbojpeg \
	libcurl4-openssl-dev \
    linux-headers-generic \
    inotify-tools

# Build libpng
RUN cd /tmp && \
	curl -L http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz | tar -zx && \
	cd /tmp/libpng-${LIBPNG_VERSION} && \
	./configure --build=$CBUILD --host=$CHOST --prefix=/usr --enable-shared --with-libpng-compat && \
	make -j${MAKE_J} install V=0

RUN cd /tmp && \
	curl -O -L https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}-stable.zip && \
	unzip v${PAGESPEED_VERSION}-stable.zip

RUN cd /tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable/ && \
	psol_url=https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz && \
	[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
	echo "URL: ${psol_url}" && \
	curl -L ${psol_url} | tar -xz

RUN cd /tmp && \
	curl -o nginx_upstream_check_module.tar.gz -L https://github.com/yaoweibin/nginx_upstream_check_module/archive/master.tar.gz  && \
	tar xfvz nginx_upstream_check_module.tar.gz


# Build in additional Nginx modules
RUN cd /tmp && \
	git clone -b v0.1.18 https://github.com/vozlt/nginx-module-vts.git && \
	git clone https://github.com/FRiCKLE/ngx_cache_purge.git && \
	git clone https://github.com/simplresty/ngx_devel_kit.git && \
	git clone https://github.com/leev/ngx_http_geoip2_module.git && \
	git clone https://github.com/openresty/echo-nginx-module.git && \
	git clone https://github.com/onnimonni/redis-nginx-module.git && \
	git clone https://github.com/openresty/redis2-nginx-module.git && \
	git clone https://github.com/openresty/srcache-nginx-module.git && \
	git clone https://github.com/openresty/set-misc-nginx-module.git && \
	git clone https://github.com/openresty/headers-more-nginx-module.git && \
	git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

RUN ls -la /tmp/
RUN ls -la /tmp/ngx_http_geoip2_module

RUN cd /tmp && \
	curl -L http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -zx && \
	cd /tmp/nginx-${NGINX_VERSION} && \
    patch -p0 < /tmp/nginx_upstream_check_module-master/check_1.11.5+.patch; \
	LD_LIBRARY_PATH=/tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}/usr/lib:/usr/lib ./configure \
	--sbin-path=/usr/sbin \
	--modules-path=/usr/lib/nginx \
	--with-http_ssl_module \
	--with-http_gzip_static_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-http_realip_module \
	--with-http_sub_module \
	--with-http_gunzip_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--without-http_autoindex_module \
	--without-http_browser_module \
	--without-http_userid_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--without-http_split_clients_module \
	--without-http_uwsgi_module \
	--without-http_scgi_module \
	--without-http_upstream_ip_hash_module \
	--prefix=/etc/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--pid-path=/var/run/nginx.pid \
	--add-module=/tmp/ngx_devel_kit \
	--add-module=/tmp/ngx_cache_purge \
	--add-module=/tmp/nginx-module-vts \
	--add-module=/tmp/echo-nginx-module \
	--add-module=/tmp/redis-nginx-module \
	--add-module=/tmp/redis2-nginx-module \
	--add-module=/tmp/srcache-nginx-module \
	--add-module=/tmp/set-misc-nginx-module \
	--add-module=/tmp/ngx_http_geoip2_module \
	--add-module=/tmp/headers-more-nginx-module \
    --add-module=/tmp/nginx_upstream_check_module-master \
	--add-module=/tmp/ngx_http_substitutions_filter_module \
	--add-module=/tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable && \
	make install --silent

# Clean-up
RUN apt-get remove -y git
RUN rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && \
	ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log && \
	mkdir -p /var/cache/ngx_pagespeed && \
	chmod -R o+wr /var/cache/ngx_pagespeed

COPY ./nginx-reloader.sh /usr/bin/nginx-reloader.sh
COPY ./docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

RUN chmod +x /usr/bin/nginx-reloader.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

RUN mkdir -p /var/ngx_pagespeed_cache
RUN chmod -R 777 /var/ngx_pagespeed_cache

EXPOSE 80 8080
WORKDIR /etc/nginx

ENTRYPOINT [ "/usr/bin/docker-entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
