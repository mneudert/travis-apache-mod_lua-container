#!/usr/bin/env bash

cd "${0%/*}"

moduledir=`pwd`
nocompile=0

if [ "${1}" == "--nocompile" ]; then
  nocompile=1

  shift
fi


echo "==> Checking parameters"

[ -z "${VER_HTTPD}" ] && echo 'parameter VER_HTTPD missing' && exit 1

[ -z "${VER_APR}" ]     && echo 'parameter VER_APR missing'     && exit 1
[ -z "${VER_APRUTIL}" ] && echo 'parameter VER_APRUTIL missing' && exit 1

[ -z "${LUA_CFLAGS}" ] && echo 'parameter LUA_CFLAGS missing' && exit 1
[ -z "${LUA_LIBS}"   ] && echo 'parameter LUA_LIBS missing'   && exit 1


if [ 0 -eq ${nocompile} ]; then
  echo "==> Downloading sources"

  [ -z `which wget` ] && echo 'can not find "wget" to download libraries' && exit 2

  mkdir -p "${moduledir}/vendor"

  cd "${moduledir}/vendor"

  if [ ! -d "httpd-${VER_HTTPD}" ]; then
    wget -q "http://apache.openmirror.de/httpd/httpd-${VER_HTTPD}.tar.gz" -O httpd.tar.gz \
      && tar -xf httpd.tar.gz
  fi

  path_srclib="httpd-${VER_HTTPD}/srclib"

  if [ ! -d "${path_srclib}/apr" ]; then
    wget -q "http://apache.openmirror.de/apr/apr-${VER_APR}.tar.gz" -O apr.tar.gz \
      && tar -xf apr.tar.gz -C "${path_srclib}" \
      && mv "${path_srclib}/apr-${VER_APR}" "${path_srclib}/apr"
  fi

  if [ ! -d "${path_srclib}/apr-util" ]; then
    wget -q "http://apache.openmirror.de/apr/apr-util-${VER_APRUTIL}.tar.gz" -O apr-util.tar.gz \
      && tar -xf apr-util.tar.gz -C "${path_srclib}" \
      && mv "${path_srclib}/apr-util-${VER_APRUTIL}" "${path_srclib}/apr-util"
  fi

  echo "==> Building Apache"

  cd "${moduledir}/vendor/httpd-${VER_HTTPD}"

  ./configure \
      --enable-lua \
      --enable-luajit \
      --with-included-apr
  make || exit $?
fi


export PATH="$PATH:${moduledir}/vendor/httpd-${VER_HTTPD}"


echo "==> Testing!"

cd "vendor/httpd-${VER_HTTPD}" \
  && mkdir "logs" \
  && ./httpd -f "${moduledir}/httpd.conf"

sleep 3

curl -sI http://localhost:8080 | grep "Apache"
