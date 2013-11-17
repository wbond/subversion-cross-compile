#!/bin/bash

if [[ $(command -v curl) == "" ]]; then
	DOWNLOAD="wget --no-check-certificate"
else
	DOWNLOAD="curl -O --insecure --location"
fi

# If gsed is available, use that since regular sed is probably the old BSD one
if [[ $(command -v gsed) != "" ]]; then
  mkdir -p bin
  ln -s $(command -v gsed) bin/sed
  export PATH="$(pwd)/bin:$PATH"
fi


$DOWNLOAD http://www.apache.org/dist/apr/apr-1.4.8-win32-src.zip
unzip apr-1.4.8-win32-src.zip
rm apr-1.4.8-win32-src.zip
mv apr-* apr

$DOWNLOAD http://www.apache.org/dist/apr/apr-util-1.5.2-win32-src.zip
unzip apr-util-1.5.2-win32-src.zip
rm apr-util-1.5.2-win32-src.zip
mv apr-util-* apr-util
 
$DOWNLOAD http://zlib.net/zlib128.zip
unzip zlib128.zip
rm zlib128.zip
mv zlib-* zlib
 
$DOWNLOAD http://www.openssl.org/source/openssl-1.0.1e.tar.gz
tar xvfz openssl-1.0.1e.tar.gz
rm openssl-1.0.1e.tar.gz
mv openssl-* openssl
 
$DOWNLOAD http://www.sqlite.org/2013/sqlite-amalgamation-3071700.zip
unzip sqlite-amalgamation-3071700.zip
rm sqlite-amalgamation-3071700.zip
mv sqlite-amalgamation-* sqlite-amalgamation
 
$DOWNLOAD https://serf.googlecode.com/files/serf-1.2.1.zip
unzip serf-1.2.1.zip
rm serf-1.2.1.zip

$DOWNLOAD http://www.webdav.org/neon/neon-0.30.0.tar.gz
tar xvfz neon-0.30.0.tar.gz
rm neon-0.30.0.tar.gz
 
$DOWNLOAD https://github.com/wbond/subversion/archive/1.8.x.zip
unzip 1.8.x
sed -i -E 's/(#define\s+SVN_VER_NUMTAG\s+)"-dev"/\1""/' subversion-1.8.x/subversion/include/svn_version.h
sed -i -E 's/(#define\s+SVN_VER_TAG\s+)" \(under development\)"/\1" (Sublime SVN)"/' subversion-1.8.x/subversion/include/svn_version.h
rm 1.8.x.zip

$DOWNLOAD https://github.com/wbond/subversion/archive/1.7.x.zip
unzip 1.7.x
sed -i -E 's/(#define\s+SVN_VER_NUMTAG\s+)"-dev"/\1""/' subversion-1.7.x/subversion/include/svn_version.h
sed -i -E 's/(#define\s+SVN_VER_TAG\s+)" \(under development\)"/\1" (Sublime SVN)"/' subversion-1.7.x/subversion/include/svn_version.h
rm 1.7.x.zip

$DOWNLOAD https://github.com/wbond/subversion/archive/1.6.x.zip
unzip 1.6.x
sed -i -E 's/(#define\s+SVN_VER_NUMTAG\s+)"-dev"/\1""/' subversion-1.6.x/subversion/include/svn_version.h
sed -i -E 's/(#define\s+SVN_VER_TAG\s+)" \(under development\)"/\1" (Sublime SVN)"/' subversion-1.6.x/subversion/include/svn_version.h
rm 1.6.x.zip
