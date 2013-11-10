#!/bin/bash

wget http://www.apache.org/dist/apr/apr-1.4.8-win32-src.zip
unzip apr-1.4.8-win32-src.zip
rm apr-1.4.8-win32-src.zip
mv apr-* apr

wget http://www.apache.org/dist/apr/apr-util-1.5.2-win32-src.zip
unzip apr-util-1.5.2-win32-src.zip
rm apr-util-1.5.2-win32-src.zip
mv apr-util-* apr-util
 
wget http://zlib.net/zlib128.zip
unzip zlib128.zip
rm zlib128.zip
mv zlib-* zlib
 
wget http://www.openssl.org/source/openssl-1.0.1e.tar.gz
tar xvfz openssl-1.0.1e.tar.gz
rm openssl-1.0.1e.tar.gz
mv openssl-* openssl
 
wget http://www.sqlite.org/2013/sqlite-amalgamation-3071700.zip
unzip sqlite-amalgamation-3071700.zip
rm sqlite-amalgamation-3071700.zip
mv sqlite-amalgamation-* sqlite-amalgamation
 
wget --no-check-certificate https://serf.googlecode.com/files/serf-1.2.1.zip
unzip serf-1.2.1.zip
rm serf-1.2.1.zip
 
wget --no-check-certificate https://serf.googlecode.com/files/serf-0.7.2.tar.gz
tar xvfz serf-0.7.2.tar.gz
rm serf-0.7.2.tar.gz
 
wget --no-check-certificate https://github.com/wbond/subversion/archive/1.8.x.zip
unzip 1.8.x
rm 1.8.x.zip

wget --no-check-certificate https://github.com/wbond/subversion/archive/1.7.x.zip
unzip 1.7.x
rm 1.7.x.zip

wget --no-check-certificate https://github.com/wbond/subversion/archive/1.6.x.zip
unzip 1.6.x
rm 1.6.x.zip
