#!/bin/bash
set -e

function show_message() {
    echo "$(date +%Y-%m-%dT%H:%M:%S)|" "$@"
}

function abort_exec() {
    reason=$*
    show_message "ERROR:" "${reason}"
    exit 1
}

apt_packages=(
    # HERD
    libgflags2.2
    libgflags-dev
    cmake
    numactl
    libnuma-dev
    # memcached
    libevent-dev
)

INSTALL_PREFIX=${INSTALL_PREFIX:-"${HOME}/.local"}

MEMCACHED_VER="1.6.9"
MEMCACHED_DIR="memcached-${MEMCACHED_VER}"
MEMCACHED_TARBALL="${MEMCACHED_DIR}.tar.gz"
MEMCACHED_TARBALL_URL="http://www.memcached.org/files/${MEMCACHED_TARBALL}"

LIBMEMCACHED_VER="1.0.18"
LIBMEMCACHED_DIR="libmemcached-${LIBMEMCACHED_VER}"
LIBMEMCACHED_TARBALL="${LIBMEMCACHED_DIR}.tar.gz"
LIBMEMCACHED_TARBALL_URL="https://launchpad.net/libmemcached/1.0/1.0.18/+download/${LIBMEMCACHED_TARBALL}"

function cleanup() {
    rm -rf "$LIBMEMCACHED_DIR" "$LIBMEMCACHED_TARBALL" "$MEMCACHED_TARBALL" "$MEMCACHED_DIR"
}

trap cleanup EXIT

show_message "install packages from apt"
sudo apt-get install "${apt_packages[@]}"

show_message "setup environment variables"
export LIBRARY_PATH="${INSTALL_PREFIX}/lib:${LIBRARY_PATH}" CPATH="${INSTALL_PREFIX}/include:${CPATH}"

show_message "download memcached and libmemcached"
[ -f "$MEMCACHED_TARBALL" ] || wget "$MEMCACHED_TARBALL_URL" -O "$MEMCACHED_TARBALL"
[ -f "$LIBMEMCACHED_TARBALL" ] || wget "$LIBMEMCACHED_TARBALL_URL" -O "$LIBMEMCACHED_TARBALL"
[ -d "$MEMCACHED_DIR" ] || tar zxf "$MEMCACHED_TARBALL"
[ -d "$LIBMEMCACHED_DIR" ] || tar zxf "$LIBMEMCACHED_TARBALL"

script_initial_dir=$(pwd)

show_message "build memcached"
cd "$MEMCACHED_DIR"
mkdir build
cd build
../configure --prefix "$INSTALL_PREFIX"
make -j8
make install
cd "$script_initial_dir"

show_message "build libmemcached"
cd "$LIBMEMCACHED_DIR"
if [ "${LIBMEMCACHED_VER}" == "1.0.18" ]; then
    # patch libmemcached source code
    sed -i 's/opt_servers == false/!opt_servers/g' clients/memflush.cc
fi
mkdir build
cd build
../configure --prefix "${INSTALL_PREFIX}" --with-memcached
make -j8
make install
cd "$script_initial_dir"

cd herd
sed -i 's/-Werror//g' Makefile
make
