#!/bin/bash

#brew install dos2unix
#brew install autoconf
#brew install gnu-sed

# For mxe
#brew install automake wget cmake intltool xz

#git clone -b stable git@github.com:mxe/mxe.git
#cd mxe
#make gcc
#cd ..

# Custom pthreads install since mxe only makes the static version
wget ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz
tar xvfz pthreads-w32-2-9-1-release.tar.gz
rm pthreads-w32-2-9-1-release.tar.gz
export PATH="$(pwd)/mxe/usr/bin:$PATH"
mv pthreads-w32-2-9-1-release pthreads-w32
cd pthreads-w32
make CROSS=i686-pc-mingw32- clean GC
cd ..
