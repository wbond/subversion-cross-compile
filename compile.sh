#!/bin/bash

BUILD_DIR=$(pwd)


# If compiling on OS X, add the MXE path
if [[ -e $BUILD_DIR/mxe ]]; then
  export PATH="$BUILD_DIR/mxe/usr/bin:$PATH"
fi


# Handle the variants in mingw32 prefix names
if [[ $(command -v i486-mingw32-gcc) != "" ]]; then
  TOOL_PREFIX=i486-mingw32
elif [[ $(command -v i686-pc-mingw32-gcc) != "" ]]; then
  TOOL_PREFIX=i686-pc-mingw32
else
  echo "Neither i486-mingw32-gcc nor i686-pc-mingw32-gcc found"
  exit 1
fi


mkdir env
mkdir env/lib
mkdir env/include
mkdir env/bin
mkdir build
mkdir bin


# Ensure we have "python" as version 2.x since many of the build scripts are assuming that
ln -s /usr/bin/python2 bin/python

# If gsed is available, use that since regular sed is probably the old BSD one
if [[ $(command -v gsed) != "" ]]; then
  ln -s $(command -v gsed) bin/sed
fi

OLD_PATH="$PATH"
export PATH="$BUILD_DIR/bin:$PATH"


# On OS X, copy pthreads to the build environment for SVN 1.8 and 1.7
if [[ -e $BUILD_DIR/pthreads-w32 ]]; then
  cp $BUILD_DIR/pthreads-w32/pthread.h $BUILD_DIR/env/include/
  cp $BUILD_DIR/pthreads-w32/sched.h $BUILD_DIR/env/include/
  cp $BUILD_DIR/pthreads-w32/semaphore.h $BUILD_DIR/env/include/
  cp $BUILD_DIR/pthreads-w32/libpthreadGC2.a $BUILD_DIR/env/lib/libpthread.a
  cp $BUILD_DIR/pthreads-w32/pthreadGC2.dll $BUILD_DIR/env/lib/
fi


cp $BUILD_DIR/patch/Ws2tcpip.h $BUILD_DIR/env/include/


cd openssl
patch -p0 < ../patch/patch-cms
patch -p0 < ../patch/patch-smime
patch -p0 < ../patch/patch-SSL_accept
patch -p0 < ../patch/patch-SSL_clear
patch -p0 < ../patch/patch-SSL_COMP_add_compression_method
patch -p0 < ../patch/patch-SSL_connect
patch -p0 < ../patch/patch-SSL_CTX_add_session
patch -p0 < ../patch/patch-SSL_CTX_load_verify_locations
patch -p0 < ../patch/patch-SSL_CTX_set_client_CA_list
patch -p0 < ../patch/patch-SSL_CTX_set_session_id_context
patch -p0 < ../patch/patch-SSL_CTX_set_ssl_version
patch -p0 < ../patch/patch-SSL_CTX_use_psk_identity_hint
patch -p0 < ../patch/patch-SSL_do_handshake
patch -p0 < ../patch/patch-SSL_read
patch -p0 < ../patch/patch-SSL_session_reused
patch -p0 < ../patch/patch-SSL_set_fd
patch -p0 < ../patch/patch-SSL_set_session
patch -p0 < ../patch/patch-SSL_shutdown
patch -p0 < ../patch/patch-SSL_write
patch -p0 < ../patch/patch-X509_STORE_CTX_get_error
CROSS_COMPILE=${TOOL_PREFIX}- ./Configure mingw shared --prefix=$BUILD_DIR/env
make depend
make
make install
cd ..


cd apr
find . -type f -exec dos2unix '{}' \;
sh buildconf
sed -i "s,#define APR_OFF_T_STRFN         strtoi,#define APR_OFF_T_STRFN         _strtoi64," "include/arch/win32/apr_private.h"
patch -p1 < ../patch/apr_arch_file_io.patch
./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --enable-shared=yes
sed -i "s,LDFLAGS=,LDFLAGS=-no-undefined ," "build/apr_rules.mk"
make
make install
cd ..


cd apr-util
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-apr=../apr --with-openssl=../openssl
sed -i "s,LDFLAGS=,LDFLAGS=-no-undefined ," "build/rules.mk"
sed -i "s,EXTRA_CPPFLAGS=,EXTRA_CPPFLAGS=-DAPU_DECLARE_EXPORT ," "build/rules.mk"
make
make install
cd ..


cd zlib
sed -i "s,PREFIX =,PREFIX = ${TOOL_PREFIX}-," win32/Makefile.gcc
sed -i "s,SHARED_MODE=0,SHARED_MODE=1," win32/Makefile.gcc
make -f win32/Makefile.gcc
make -f win32/Makefile.gcc install DESTDIR=$BUILD_DIR/env INCLUDE_PATH=/include LIBRARY_PATH=/lib BINARY_PATH=/bin
cd ..


cd serf-1.2.1
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=${TOOL_PREFIX} --with-apr=$BUILD_DIR/env --with-apr-util=$BUILD_DIR/env --with-openssl=$BUILD_DIR/openssl --prefix=$BUILD_DIR/env CPPFLAGS=-I$BUILD_DIR/env/include LDFLAGS="-L$BUILD_DIR/env/lib"
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
make
make install
cd ..


cd serf-0.7.2
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=${TOOL_PREFIX} --with-apr=$BUILD_DIR/env --with-apr-util=$BUILD_DIR/env --with-openssl=$BUILD_DIR/openssl --prefix=$BUILD_DIR/env CPPFLAGS=-I$BUILD_DIR/env/include LDFLAGS="-L$BUILD_DIR/env/lib"
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
make
make install
cd ..


${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.dll


cd subversion-1.8.x
cp -R ../sqlite-amalgamation ./

sh autogen.sh

./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-apr=../apr --with-apr-util=../apr-util --with-openssl=../openssl --disable-static --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --without-gpg-agent --with-gnome-keyring=no --enable-shared --without-apxs CPPFLAGS=-I$BUILD_DIR/env/include

make fsmod-lib ramod-lib lib bin

make install

${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.dll
${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.exe

mkdir $BUILD_DIR/build/1.8/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.8/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.8/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*
cd ..


cd subversion-1.7.x
cp -R ../sqlite-amalgamation ./

sh autogen.sh

./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-apr=../apr --with-apr-util=../apr-util --with-openssl=../openssl --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --with-gnome-keyring=no --enable-shared=yes --with-neon=no --with-gssapi=no --without-apxs CPPFLAGS=-I$BUILD_DIR/env/include

make fsmod-lib ramod-lib lib bin

make install

${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.dll
${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.exe

mkdir $BUILD_DIR/build/1.7/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.7/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.7/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*
cd ..


cd subversion-1.6.x
cp -R ../sqlite-amalgamation ./

sh autogen.sh

./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-apr=../env --with-apr-util=../env --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --with-gnome-keyring=no --enable-shared=yes --with-neon=no --without-apxs CPPFLAGS=-I$BUILD_DIR/apr/include


make fsmod-lib ramod-lib lib bin

make install

${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.dll
${TOOL_PREFIX}-strip $BUILD_DIR/env/bin/*.exe

mkdir $BUILD_DIR/build/1.6/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.6/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.6/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*
cd ..


cp $BUILD_DIR/env/bin/*.dll $BUILD_DIR/build


export PATH="$OLD_PATH"
