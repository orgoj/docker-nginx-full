#!/bin/bash -e

BLUE='\E[1;34m'
CYAN='\E[1;36m'
YELLOW='\E[1;33m'
GREEN='\E[1;32m'
RESET='\E[0m'

echo -e "${BLUE}❯ ${CYAN}Building OpenResty ${YELLOW}${OPENRESTY_VERSION} with nginx_http_geoip2, brotli and zstd modules...${RESET}"

cd /tmp

# The official releases:
# wget "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz" -O "openresty-${OPENRESTY_VERSION}.tar.gz"

# The github tagged releases:
wget "https://github.com/openresty/openresty/archive/refs/tags/v${OPENRESTY_VERSION}.tar.gz" -O "openresty-${OPENRESTY_VERSION}.tar.gz"

tar -xzf "openresty-${OPENRESTY_VERSION}.tar.gz"
mv "/tmp/openresty-${OPENRESTY_VERSION}" /tmp/openresty
git clone 'https://github.com/leev/ngx_http_geoip2_module.git'
mv /tmp/ngx_http_geoip2_module /tmp/openresty/ngx_http_geoip2_module

# Compression modules, pinned by commit and archive checksum
NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53
NGX_BROTLI_SHA256=1d21be34f3b7b6d05a8142945e59b3a47665edcdfe0f3ee3d3dbef121f90c08c
NGX_ZSTD_COMMIT=057a7d339af1111d04b5a9ac5ae9b0250d17cd94
NGX_ZSTD_SHA256=6f03d047cb5b2045d5622e37eb9ce4f67b9880214d5781e8656e4b8b33e25465

wget "https://github.com/google/ngx_brotli/archive/${NGX_BROTLI_COMMIT}.tar.gz" -O ngx_brotli.tar.gz
echo "${NGX_BROTLI_SHA256}  ngx_brotli.tar.gz" | sha256sum -c -
tar -xzf ngx_brotli.tar.gz
mv "/tmp/ngx_brotli-${NGX_BROTLI_COMMIT}" /tmp/openresty/ngx_brotli
# Use the Debian brotli library (libbrotli-dev) instead of the git submodule.
# Copy, not symlink: the final stage runs make install on this tree without libbrotli-dev.
mkdir -p /tmp/openresty/ngx_brotli/deps/brotli/c/include
cp -r /usr/include/brotli /tmp/openresty/ngx_brotli/deps/brotli/c/include/brotli

wget "https://github.com/tokers/zstd-nginx-module/archive/${NGX_ZSTD_COMMIT}.tar.gz" -O zstd-nginx-module.tar.gz
echo "${NGX_ZSTD_SHA256}  zstd-nginx-module.tar.gz" | sha256sum -c -
tar -xzf zstd-nginx-module.tar.gz
mv "/tmp/zstd-nginx-module-${NGX_ZSTD_COMMIT}" /tmp/openresty/zstd-nginx-module

cd /tmp/openresty

make

cd "/tmp/openresty/openresty-${OPENRESTY_VERSION}"

./configure \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-compat \
	--with-threads \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-http_v3_module \
	--add-module=/tmp/openresty/ngx_brotli \
	--add-module=/tmp/openresty/zstd-nginx-module \
	--add-dynamic-module=/tmp/openresty/ngx_http_geoip2_module

make -j"$(nproc)"

echo -e "${BLUE}❯ ${GREEN}OpenResty build completed${RESET}"
