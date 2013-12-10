#!/bin/bash

set -e

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


mkdir -p env
mkdir -p env/lib
mkdir -p env/include
mkdir -p env/bin
mkdir -p build
mkdir -p bin


# Ensure we have "python" as version 2.x since many of the build scripts are assuming that
if [[ ! -h bin/python ]]; then
  ln -s /usr/bin/python2 bin/python
fi

# If gsed is available, use that since regular sed is probably the old BSD one
if [[ $(command -v gsed) != "" && ! -h bin/sed ]]; then
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

# Customized to include a couple of extra constants
cp $BUILD_DIR/patch/wincrypt.h $BUILD_DIR/env/include/

# Creates a .dll.a file for the purpose of linking subversion so it can
# use the native windows password encryption functionality
${TOOL_PREFIX}-dlltool -k -d $BUILD_DIR/patch/crypt32.def -l $BUILD_DIR/env/lib/crypt32.dll.a


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


cd serf-1.3.2
patch -p1 < ../patch/serf-1.3.2.patch
scons APR=$BUILD_DIR/env APU=$BUILD_DIR/env OPENSSL=$BUILD_DIR/openssl PREFIX=$BUILD_DIR/env CPPFLAGS=-I$BUILD_DIR/env/include LINKFLAGS="-L$BUILD_DIR/env/lib" CC=$(command -v ${TOOL_PREFIX}-gcc) install
cd ..


cd neon-0.30.0
ne_cv_os_uname=MINGW ./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-ssl --with-expat --disable-nls --enable-shared --disable-static --with-libs=/Users/wbond/dev/git/subversion-compile/env CPPFLAGS=-I$BUILD_DIR/env/include/apr-1
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

./configure --host=${TOOL_PREFIX} --prefix=$BUILD_DIR/env --with-apr=../env --with-apr-util=../env --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --with-gnome-keyring=no --enable-shared=yes --with-serf=no --without-apxs --with-neon=../env CPPFLAGS=-I$BUILD_DIR/apr/include

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
