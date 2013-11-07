#!/bin/bash

BUILD_DIR=$(pwd)


mkdir env
mkdir env/lib
mkdir env/include
mkdir env/bin
mkdir build


cd openssl
CROSS_COMPILE=i486-mingw32- ./Configure mingw shared --prefix=$BUILD_DIR/env
make depend
make
make install


cd apr
find . -type f -exec dos2unix '{}' \;
sh buildconf
sed -i "s,#define APR_OFF_T_STRFN         strtoi,#define APR_OFF_T_STRFN         _strtoi64," "include/arch/win32/apr_private.h"
patch -p1 <<EOF
--- a/include/arch/win32/apr_arch_file_io.h  2013-07-22 23:20:10.276986234 -0400
+++ b/include/arch/win32/apr_arch_file_io.h  2013-07-22 23:20:24.326984422 -0400
@@ -171,18 +171,18 @@
     char *fname;
     DWORD dwFileAttributes;
     int eof_hit;
-    BOOLEAN buffered;          // Use buffered I/O?
-    int ungetchar;             // Last char provided by an unget op. (-1 = no char)
+    BOOLEAN buffered;          /* Use buffered I/O? */
+    int ungetchar;             /* Last char provided by an unget op. (-1 = no char) */
     int append; 
 
     /* Stuff for buffered mode */
     char *buffer;
-    apr_size_t bufpos;         // Read/Write position in buffer
-    apr_size_t bufsize;        // The size of the buffer
-    apr_size_t dataRead;       // amount of valid data read into buffer
-    int direction;             // buffer being used for 0 = read, 1 = write
-    apr_off_t filePtr;         // position in file of handle
-    apr_thread_mutex_t *mutex; // mutex semaphore, must be owned to access the above fields
+    apr_size_t bufpos;         /* Read/Write position in buffer */
+    apr_size_t bufsize;        /* The size of the buffer */
+    apr_size_t dataRead;       /* amount of valid data read into buffer */
+    int direction;             /* buffer being used for 0 = read, 1 = write */
+    apr_off_t filePtr;         /* position in file of handle */
+    apr_thread_mutex_t *mutex; /* mutex semaphore, must be owned to access the above fields */
 
     /* if there is a timeout set, then this pollset is used */
     apr_pollset_t *pollset;
EOF
./configure --host=i486-mingw32 --prefix=$BUILD_DIR/env --enable-shared=yes
sed -i "s,LDFLAGS=,LDFLAGS=-no-undefined ," "build/apr_rules.mk"
make
make install


cd ../apr-util
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=i486-mingw32 --prefix=$BUILD_DIR/env --with-apr=../apr --with-openssl=../openssl
sed -i "s,LDFLAGS=,LDFLAGS=-no-undefined ," "build/rules.mk"
sed -i "s,EXTRA_CPPFLAGS=,EXTRA_CPPFLAGS=-DAPU_DECLARE_EXPORT ," "build/rules.mk"
make
make install



cd ../zlib
sed -i "s,PREFIX =,PREFIX = i486-mingw32-," win32/Makefile.gcc
sed -i "s,SHARED_MODE=0,SHARED_MODE=1," win32/Makefile.gcc
make -f win32/Makefile.gcc
make -f win32/Makefile.gcc install DESTDIR=$BUILD_DIR/env INCLUDE_PATH=/include LIBRARY_PATH=/lib BINARY_PATH=/bin


cd ../serf-1.2.1
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=i486-mingw32 --with-apr=$BUILD_DIR/env --with-apr-util=$BUILD_DIR/env --with-openssl=$BUILD_DIR/openssl --prefix=$BUILD_DIR/env CPPFLAGS=-I$BUILD_DIR/env/include LDFLAGS="-L$BUILD_DIR/env/lib"
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
make
make install

cd ../serf-0.7.2
find . -type f -exec dos2unix '{}' \;
sh buildconf
./configure --host=i486-mingw32 --with-apr=$BUILD_DIR/env --with-apr-util=$BUILD_DIR/env --with-openssl=$BUILD_DIR/openssl --prefix=$BUILD_DIR/env CPPFLAGS=-I$BUILD_DIR/env/include LDFLAGS="-L$BUILD_DIR/env/lib"
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
make
make install



i486-mingw32-strip $BUILD_DIR/env/*.dll



cd ../subversion-1.8.x
cp -R ../sqlite-amalgamation ./

# This autoconf stuff for OS X gives errors when cross-compiling
rm build/ac-macros/macosx.m4
# This autoconf stuff for swig throws errors about
# python and we don't want swig anyway
rm build/ac-macros/swig.m4

sh autogen.sh

./configure --host=i486-mingw32 --prefix=$BUILD_DIR/env --with-apr=../apr --with-apr-util=../apr-util --with-openssl=../openssl --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --without-gpg-agent --with-gnome-keyring=no --enable-shared=yes CPPFLAGS=-I$BUILD_DIR/env/include

echo "#define SHGFP_TYPE_CURRENT 0" >> subversion/svn_private_config.h
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
sed -E -i "s,^LIBS = ,LIBS = -lpsapi -lversion -lole32 ," Makefile

patch -p1 <<EOF
--- a/subversion/libsvn_subr/win32_xlate.c  2013-07-25 03:30:43.357437797 -0400
+++ b/subversion/libsvn_subr/win32_xlate.c  2013-07-25 03:31:24.687109811 -0400
@@ -50,6 +50,10 @@
 
 #include "win32_xlate.h"
 
+#include <malloc.h>
+const IID IID_IMultiLanguage = {0x275c23e1,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+const CLSID CLSID_CMultiLanguage = {0x275c23e2,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+
 static svn_atomic_t com_initialized = 0;
 
 /* Initializes COM and keeps COM available until process exit.
EOF

patch -p1 <<EOF
--- a/subversion/libsvn_subr/cmdline.c  2013-07-25 03:54:32.139711189 -0400
+++ b/subversion/libsvn_subr/cmdline.c  2013-07-25 03:54:44.949813627 -0400
@@ -32,7 +32,6 @@
 #include <fcntl.h>
 #include <unistd.h>
 #else
-#include <crtdbg.h>
 #include <io.h>
 #endif
 
@@ -134,27 +133,6 @@
   /* Attach (but don't load) the crash handler */
   SetUnhandledExceptionFilter(svn__unhandled_exception_filter);
 
-#if _MSC_VER >= 1400
-  /* ### This should work for VC++ 2002 (=1300) and later */
-  /* Show the abort message on STDERR instead of a dialog to allow
-     scripts (e.g. our testsuite) to continue after an abort without
-     user intervention. Allow overriding for easier debugging. */
-  if (!getenv("SVN_CMDLINE_USE_DIALOG_FOR_ABORT"))
-    {
-      /* In release mode: Redirect abort() errors to stderr */
-      _set_error_mode(_OUT_TO_STDERR);
-
-      /* In _DEBUG mode: Redirect all debug output (E.g. assert() to stderr.
-         (Ignored in release builds) */
-      _CrtSetReportFile( _CRT_WARN, _CRTDBG_FILE_STDERR);
-      _CrtSetReportFile( _CRT_ERROR, _CRTDBG_FILE_STDERR);
-      _CrtSetReportFile( _CRT_ASSERT, _CRTDBG_FILE_STDERR);
-      _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-      _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-      _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-    }
-#endif /* _MSC_VER >= 1400 */
-
 #endif /* SVN_USE_WIN32_CRASHHANDLER */
 
 #endif /* WIN32 */
EOF

WINTCP=$(cat <<'SETVAR'
/*
 *  ws2tcpip.h : TCP/IP specific extensions in Windows Sockets 2
 *
 * Portions Copyright (c) 1980, 1983, 1988, 1993
 * The Regents of the University of California.  All rights reserved.
 *
 */

#ifndef _WS2TCPIP_H
#define _WS2TCPIP_H
#if __GNUC__ >=3
#pragma GCC system_header
#endif

#if (defined _WINSOCK_H && !defined _WINSOCK2_H)
#error "ws2tcpip.h is not compatible with winsock.h. Include winsock2.h instead."
#endif

#include <winsock2.h>
#ifdef  __cplusplus
extern "C" {
#endif

/* 
 * The IP_* macros are also defined in winsock.h, but some values are different there.
 * The values defined in winsock.h for 1.1 and used in wsock32.dll are consistent
 * with the original values Steve Deering defined in his document "IP Multicast Extensions
 * for 4.3BSD UNIX related systems (MULTICAST 1.2 Release)." However, these conflicted with
 * the definitions for some IPPROTO_IP level socket options already assigned by BSD,
 * so Berkeley changed all the values by adding 7.  WinSock2 (ws2_32.dll)  uses
 * the BSD 4.4 compatible values defined here.
 *
 * See also: msdn kb article Q257460
 * http://support.microsoft.com/support/kb/articles/Q257/4/60.asp
 */

/* This is also defined in winsock.h; value hasn't changed */
#define	IP_OPTIONS  1

#define	IP_HDRINCL  2
/*
 * These are also be defined in winsock.h,
 * but values have changed for WinSock2 interface
 */
#define IP_TOS			3   /* old (winsock 1.1) value 8 */
#define IP_TTL			4   /* old value 7 */
#define IP_MULTICAST_IF		9   /* old value 2 */
#define IP_MULTICAST_TTL	10  /* old value 3 */
#define IP_MULTICAST_LOOP	11  /* old value 4 */
#define IP_ADD_MEMBERSHIP	12  /* old value 5 */
#define IP_DROP_MEMBERSHIP	13  /* old value 6 */
#define IP_DONTFRAGMENT		14  /* old value 9 */
#define IP_ADD_SOURCE_MEMBERSHIP	15
#define IP_DROP_SOURCE_MEMBERSHIP	16
#define IP_BLOCK_SOURCE			17
#define IP_UNBLOCK_SOURCE		18
#define IP_PKTINFO			19

/*
 * As with BSD implementation, IPPROTO_IPV6 level socket options have
 * same values as IPv4 counterparts.
 */
#define IPV6_UNICAST_HOPS	4
#define IPV6_MULTICAST_IF	9
#define IPV6_MULTICAST_HOPS	10
#define IPV6_MULTICAST_LOOP	11
#define IPV6_ADD_MEMBERSHIP	12
#define IPV6_DROP_MEMBERSHIP	13
#define IPV6_JOIN_GROUP		IPV6_ADD_MEMBERSHIP
#define IPV6_LEAVE_GROUP	IPV6_DROP_MEMBERSHIP
#define IPV6_PKTINFO		19

#define IP_DEFAULT_MULTICAST_TTL 1 
#define IP_DEFAULT_MULTICAST_LOOP 1 
#define IP_MAX_MEMBERSHIPS 20 

#define TCP_EXPEDITED_1122  2

#define UDP_NOCHECKSUM 1

/* INTERFACE_INFO iiFlags */
#define IFF_UP  1
#define IFF_BROADCAST   2
#define IFF_LOOPBACK    4
#define IFF_POINTTOPOINT    8
#define IFF_MULTICAST   16

#define SIO_GET_INTERFACE_LIST  _IOR('t', 127, u_long)

#define INET_ADDRSTRLEN  16
#define INET6_ADDRSTRLEN 46

/* getnameinfo constants */ 
#define NI_MAXHOST	1025
#define NI_MAXSERV	32

#define NI_NOFQDN 	0x01
#define NI_NUMERICHOST	0x02
#define NI_NAMEREQD	0x04
#define NI_NUMERICSERV	0x08
#define NI_DGRAM	0x10

/* getaddrinfo constants */
#define AI_PASSIVE	1
#define AI_CANONNAME	2
#define AI_NUMERICHOST	4

/* getaddrinfo error codes */
#define EAI_AGAIN	WSATRY_AGAIN
#define EAI_BADFLAGS	WSAEINVAL
#define EAI_FAIL	WSANO_RECOVERY
#define EAI_FAMILY	WSAEAFNOSUPPORT
#define EAI_MEMORY	WSA_NOT_ENOUGH_MEMORY
#define EAI_NODATA	WSANO_DATA
#define EAI_NONAME	WSAHOST_NOT_FOUND
#define EAI_SERVICE	WSATYPE_NOT_FOUND
#define EAI_SOCKTYPE	WSAESOCKTNOSUPPORT

/*
 *   ip_mreq also in winsock.h for WinSock1.1,
 *   but online msdn docs say it is defined here for WinSock2.
 */ 

struct ip_mreq {
	struct in_addr	imr_multiaddr;
	struct in_addr	imr_interface;
};

struct ip_mreq_source {
	struct in_addr	imr_multiaddr;
	struct in_addr	imr_sourceaddr;
	struct in_addr	imr_interface;
};

struct ip_msfilter {
	struct in_addr	imsf_multiaddr;
	struct in_addr	imsf_interface;
	u_long		imsf_fmode;
	u_long		imsf_numsrc;
	struct in_addr	imsf_slist[1];
};

#define IP_MSFILTER_SIZE(numsrc) \
   (sizeof(struct ip_msfilter) - sizeof(struct in_addr) \
   + (numsrc) * sizeof(struct in_addr))

struct in_pktinfo {
	IN_ADDR ipi_addr;
	UINT    ipi_ifindex;
};
typedef struct in_pktinfo IN_PKTINFO;


/* ipv6 */ 
/* These require XP or .NET Server or use of add-on IPv6 stacks on NT 4
  or higher */

/* This is based on the example given in RFC 2553 with stdint types
   changed to BSD types.  For now, use these  field names until there
   is some consistency in MS docs. In this file, we only use the
   in6_addr structure start address, with casts to get the right offsets
   when testing addresses */
  
struct in6_addr {
    union {
        u_char	_S6_u8[16];
        u_short	_S6_u16[8];
        u_long	_S6_u32[4];
        } _S6_un;
};
/* s6_addr is the standard name */
#define s6_addr		_S6_un._S6_u8

/* These are GLIBC names */ 
#define s6_addr16	_S6_un._S6_u16
#define s6_addr32	_S6_un._S6_u32

/* These are used in some MS code */
#define in_addr6	in6_addr
#define _s6_bytes	_S6_un._S6_u8
#define _s6_words	_S6_un._S6_u16

typedef struct in6_addr IN6_ADDR,  *PIN6_ADDR, *LPIN6_ADDR;

struct sockaddr_in6 {
	short sin6_family;	/* AF_INET6 */
	u_short sin6_port; 	/* transport layer port # */
	u_long sin6_flowinfo;	/* IPv6 traffic class & flow info */
	struct in6_addr sin6_addr;  /* IPv6 address */
	u_long sin6_scope_id;	/* set of interfaces for a scope */
};
typedef struct sockaddr_in6 SOCKADDR_IN6, *PSOCKADDR_IN6, *LPSOCKADDR_IN6;

extern const struct in6_addr in6addr_any;
extern const struct in6_addr in6addr_loopback;
/* the above can get initialised using: */ 
#define IN6ADDR_ANY_INIT        { 0 }
#define IN6ADDR_LOOPBACK_INIT   { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 }

/* Described in RFC 2292, but not in 2553 */
/* int IN6_ARE_ADDR_EQUAL(const struct in6_addr * a, const struct in6_addr * b) */
#define IN6_ARE_ADDR_EQUAL(a, b)	\
    (memcmp ((void*)(a), (void*)(b), sizeof (struct in6_addr)) == 0)


/* Address Testing Macros 

 These macro functions all take const struct in6_addr* as arg.
 Static inlines would allow type checking, but RFC 2553 says they
 macros.	 
 NB: These are written specifically for little endian host */

#define IN6_IS_ADDR_UNSPECIFIED(_addr) \
	(   (((const u_long *)(_addr))[0] == 0)	\
	 && (((const u_long *)(_addr))[1] == 0)	\
	 && (((const u_long *)(_addr))[2] == 0)	\
	 && (((const u_long *)(_addr))[3] == 0))

#define IN6_IS_ADDR_LOOPBACK(_addr) \
	(   (((const u_long *)(_addr))[0] == 0)	\
	 && (((const u_long *)(_addr))[1] == 0)	\
	 && (((const u_long *)(_addr))[2] == 0)	\
	 && (((const u_long *)(_addr))[3] == 0x01000000)) /* Note byte order reversed */
/*	    (((const u_long *)(_addr))[3] == ntohl(1))  */

#define IN6_IS_ADDR_MULTICAST(_addr) (((const u_char *) (_addr))[0] == 0xff)

#define IN6_IS_ADDR_LINKLOCAL(_addr) \
	(   (((const u_char *)(_addr))[0] == 0xfe)	\
	 && ((((const u_char *)(_addr))[1] & 0xc0) == 0x80))

#define IN6_IS_ADDR_SITELOCAL(_addr) \
	(   (((const u_char *)(_addr))[0] == 0xfe)	\
	 && ((((const u_char *)(_addr))[1] & 0xc0) == 0xc0))

#define IN6_IS_ADDR_V4MAPPED(_addr) \
	(   (((const u_long *)(_addr))[0] == 0)		\
	 && (((const u_long *)(_addr))[1] == 0)		\
	 && (((const u_long *)(_addr))[2] == 0xffff0000)) /* Note byte order reversed */
/* 	    (((const u_long *)(_addr))[2] == ntohl(0x0000ffff))) */

#define IN6_IS_ADDR_V4COMPAT(_addr) \
	(   (((const u_long *)(_addr))[0] == 0)		\
	 && (((const u_long *)(_addr))[1] == 0)		\
	 && (((const u_long *)(_addr))[2] == 0)		\
	 && (((const u_long *)(_addr))[3] != 0)		\
	 && (((const u_long *)(_addr))[3] != 0x01000000)) /* Note byte order reversed */
/*           (ntohl (((const u_long *)(_addr))[3]) > 1 ) */


#define IN6_IS_ADDR_MC_NODELOCAL(_addr)	\
	(   IN6_IS_ADDR_MULTICAST(_addr)		\
	 && ((((const u_char *)(_addr))[1] & 0xf) == 0x1)) 

#define IN6_IS_ADDR_MC_LINKLOCAL(_addr)	\
	(   IN6_IS_ADDR_MULTICAST (_addr)		\
	 && ((((const u_char *)(_addr))[1] & 0xf) == 0x2))

#define IN6_IS_ADDR_MC_SITELOCAL(_addr)	\
	(   IN6_IS_ADDR_MULTICAST(_addr)		\
	 && ((((const u_char *)(_addr))[1] & 0xf) == 0x5))

#define IN6_IS_ADDR_MC_ORGLOCAL(_addr)	\
	(   IN6_IS_ADDR_MULTICAST(_addr)		\
	 && ((((const u_char *)(_addr))[1] & 0xf) == 0x8))

#define IN6_IS_ADDR_MC_GLOBAL(_addr)	\
	(   IN6_IS_ADDR_MULTICAST(_addr)	\
	 && ((((const u_char *)(_addr))[1] & 0xf) == 0xe))


typedef int socklen_t;

struct ipv6_mreq {
	struct in6_addr ipv6mr_multiaddr;
	unsigned int    ipv6mr_interface;
};
typedef struct ipv6_mreq IPV6_MREQ;

struct in6_pktinfo {
	IN6_ADDR ipi6_addr;
	UINT     ipi6_ifindex;
};
typedef struct  in6_pktinfo IN6_PKTINFO;

struct addrinfo {
	int     ai_flags;
	int     ai_family;
	int     ai_socktype;
	int     ai_protocol;
	size_t  ai_addrlen;
	char   *ai_canonname;
	struct sockaddr  *ai_addr;
	struct addrinfo  *ai_next;
};

#if (_WIN32_WINNT >= 0x0501)
void WSAAPI freeaddrinfo (struct addrinfo*);
int WSAAPI getaddrinfo (const char*,const char*,const struct addrinfo*,
		        struct addrinfo**);
int WSAAPI getnameinfo(const struct sockaddr*,socklen_t,char*,DWORD,
		       char*,DWORD,int);
#else
/* FIXME: Need WS protocol-independent API helpers.  */
#endif

static __inline char*
gai_strerrorA(int ecode)
{
	static char message[1024+1];
	DWORD dwFlags = FORMAT_MESSAGE_FROM_SYSTEM
	              | FORMAT_MESSAGE_IGNORE_INSERTS
		      | FORMAT_MESSAGE_MAX_WIDTH_MASK;
	DWORD dwLanguageId = MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT);
  	FormatMessageA(dwFlags, NULL, ecode, dwLanguageId, (LPSTR)message, 1024, NULL);
	return message;
}
static __inline WCHAR*
gai_strerrorW(int ecode)
{
	static WCHAR message[1024+1];
	DWORD dwFlags = FORMAT_MESSAGE_FROM_SYSTEM
	              | FORMAT_MESSAGE_IGNORE_INSERTS
		      | FORMAT_MESSAGE_MAX_WIDTH_MASK;
	DWORD dwLanguageId = MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT);
  	FormatMessageW(dwFlags, NULL, ecode, dwLanguageId, (LPWSTR)message, 1024, NULL);
	return message;
}
#ifdef UNICODE
#define gai_strerror gai_strerrorW
#else
#define gai_strerror gai_strerrorA
#endif

/* Some older IPv4/IPv6 compatibility stuff */

/* This struct lacks sin6_scope_id; retained for use in sockaddr_gen */
struct sockaddr_in6_old {
	short   sin6_family;
	u_short sin6_port;
	u_long  sin6_flowinfo;
	struct in6_addr sin6_addr;
};

typedef union sockaddr_gen{
	struct sockaddr		Address;
	struct sockaddr_in	AddressIn;
	struct sockaddr_in6_old	AddressIn6;
} sockaddr_gen;


typedef struct _INTERFACE_INFO {
	u_long		iiFlags;
	sockaddr_gen	iiAddress;
	sockaddr_gen	iiBroadcastAddress;
	sockaddr_gen	iiNetmask;
} INTERFACE_INFO, *LPINTERFACE_INFO;

/*
   The definition above can cause problems on NT4,prior to sp4.
   To workaround, include the following struct and typedef and
   #define INTERFACE_INFO OLD_INTERFACE_INFO
   See: FIX: WSAIoctl SIO_GET_INTERFACE_LIST Option Problem
   (Q181520) in MSDN KB.

   The old definition causes problems on newer NT and on XP.

typedef struct _OLD_INTERFACE_INFO {
	u_long		iiFlags;
	struct sockaddr	iiAddress;
 	struct sockaddr	iiBroadcastAddress;
 	struct sockaddr	iiNetmask;
} OLD_INTERFACE_INFO;
*/

#ifdef  __cplusplus
}
#endif
#endif
SETVAR
)

echo "$WINTCP" > $BUILD_DIR/env/include/Ws2tcpip.h

make fsmod-lib ramod-lib lib bin

make install

i486-mingw32-strip $BUILD_DIR/env/*.dll
i486-mingw32-strip $BUILD_DIR/env/*.exe

mkdir $BUILD_DIR/build/1.8/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.8/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.8/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*


cd ../subversion-1.7.x
cp -R ../sqlite-amalgamation ./

# This autoconf stuff for swig throws errors about
# python and we don't want swig anyway
rm build/ac-macros/swig.m4

sh autogen.sh

./configure --host=i486-mingw32 --prefix=$BUILD_DIR/env --with-apr=../apr --with-apr-util=../apr-util --with-openssl=../openssl --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --with-gnome-keyring=no --enable-shared=yes --with-neon=no --with-gssapi=no  CPPFLAGS=-I$BUILD_DIR/env/include
echo "#define SHGFP_TYPE_CURRENT 0" >> subversion/svn_private_config.h
sed -i "s,LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
sed -i "s,SVN_SQLITE_LIBS = -ldl ,SVN_SQLITE_LIBS = ," Makefile
sed -E -i "s,^LIBS = ,LIBS = -lole32 ," Makefile

patch -p1 <<EOF
--- a/subversion/libsvn_subr/win32_xlate.c  2013-07-25 10:27:57.056122024 -0400
+++ b/subversion/libsvn_subr/win32_xlate.c  2013-07-25 10:32:49.889105318 -0400
@@ -47,6 +47,11 @@
 
 #include "win32_xlate.h"
 
+#include <malloc.h>
+const IID IID_IMultiLanguage = {0x275c23e1,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+const CLSID CLSID_CMultiLanguage = {0x275c23e2,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+
 static svn_atomic_t com_initialized = 0;
 
 /* Initializes COM and keeps COM available until process exit.
EOF

patch -p1 <<EOF
--- a/subversion/libsvn_subr/cmdline.c  2013-07-25 10:23:46.776398887 -0400
+++ b/subversion/libsvn_subr/cmdline.c  2013-07-25 10:24:39.229673749 -0400
@@ -31,8 +31,6 @@
 #include <sys/stat.h>
 #include <fcntl.h>
 #include <unistd.h>
-#else
-#include <crtdbg.h>
 #endif
 
 #include <apr_errno.h>          /* for apr_strerror */
@@ -126,25 +124,6 @@
   /* Attach (but don't load) the crash handler */
   SetUnhandledExceptionFilter(svn__unhandled_exception_filter);
 
-#if _MSC_VER >= 1400
-  /* ### This should work for VC++ 2002 (=1300) and later */
-  /* Show the abort message on STDERR instead of a dialog to allow
-     scripts (e.g. our testsuite) to continue after an abort without
-     user intervention. Allow overriding for easier debugging. */
-  if (!getenv("SVN_CMDLINE_USE_DIALOG_FOR_ABORT"))
-    {
-      /* In release mode: Redirect abort() errors to stderr */
-      _set_error_mode(_OUT_TO_STDERR);
-
-      /* In _DEBUG mode: Redirect all debug output (E.g. assert() to stderr.
-         (Ignored in releas builds) */
-      _CrtSetReportFile( _CRT_ASSERT, _CRTDBG_FILE_STDERR);
-      _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-      _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-      _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG);
-    }
-#endif /* _MSC_VER >= 1400 */
-
 #endif /* SVN_USE_WIN32_CRASHHANDLER */
 
 #endif /* WIN32 */
EOF

make fsmod-lib ramod-lib lib bin

make install

i486-mingw32-strip $BUILD_DIR/env/*.dll
i486-mingw32-strip $BUILD_DIR/env/*.exe

mkdir $BUILD_DIR/build/1.7/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.7/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.7/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*



cd ../subversion-1.6.x
cp -R ../sqlite-amalgamation ./

# This autoconf stuff for swig throws errors about
# python and we don't want swig anyway
rm build/ac-macros/swig.m4

# Ensure that serf is properly detected
patch -p1 <<EOF
--- a/build/ac-macros/aprutil.m4  2013-07-25 15:16:52.226235509 -0400
+++ b/build/ac-macros/aprutil.m4  2013-07-25 15:17:01.576233551 -0400
@@ -79,14 +79,26 @@
 
   dnl When APR stores the dependent libs in the .la file, we don't need
   dnl --libs.
-  SVN_APRUTIL_LIBS="`$apu_config --link-libtool --libs`"
-  if test $? -ne 0; then
-    AC_MSG_ERROR([apu-config --link-libtool --libs failed])
-  fi
+  if test "$enable_all_static" = "yes"; then
+    SVN_APRUTIL_LIBS="`$apu_config --link-libtool --libs`"
+    if test $? -ne 0; then
+      AC_MSG_ERROR([apu-config --link-libtool --libs failed])
+    fi
+
+    SVN_APRUTIL_EXPORT_LIBS="`$apu_config --link-ld --libs`"
+    if test $? -ne 0; then
+      AC_MSG_ERROR([apu-config --link-ld --libs failed])
+    fi
+  else
+    SVN_APRUTIL_LIBS="`$apu_config --link-libtool`"
+    if test $? -ne 0; then
+      AC_MSG_ERROR([apu-config --link-libtool failed])
+    fi
 
-  SVN_APRUTIL_EXPORT_LIBS="`$apu_config --link-ld --libs`"
-  if test $? -ne 0; then
-    AC_MSG_ERROR([apu-config --link-ld --libs failed])
+    SVN_APRUTIL_EXPORT_LIBS="`$apu_config --link-ld`"
+    if test $? -ne 0; then
+      AC_MSG_ERROR([apu-config --link-ld failed])
+    fi
   fi
 
   AC_SUBST(SVN_APRUTIL_INCLUDES)
EOF

sh autogen.sh

./configure --host=i486-mingw32 --prefix=$BUILD_DIR/env --with-apr=../env --with-apr-util=../env --enable-static=no --disable-nls --with-serf=$BUILD_DIR/env --with-zlib=$BUILD_DIR/env --with-gnome-keyring=no --enable-shared=yes --with-neon=no CPPFLAGS=-I$BUILD_DIR/env/include
echo "#define SHGFP_TYPE_CURRENT 0" >> subversion/svn_private_config.h
sed -E -i "s,^LDFLAGS = ,LDFLAGS = -no-undefined ," Makefile
sed -E -i "s,^LIBS = ,LIBS = -lole32 ," Makefile

patch -p1 <<EOF
--- a/subversion/libsvn_ra_serf/ra_serf.h  2013-07-25 15:24:54.236202115 -0400
+++ b/subversion/libsvn_ra_serf/ra_serf.h  2013-07-25 15:25:04.816203090 -0400
@@ -49,10 +49,6 @@
                    APR_STRINGIFY(SERF_MINOR_VERSION) "." \
                    APR_STRINGIFY(SERF_PATCH_VERSION)
 
-#ifdef WIN32
-#define SVN_RA_SERF_SSPI_ENABLED
-#endif
-
 
 /* Forward declarations. */
 typedef struct svn_ra_serf__session_t svn_ra_serf__session_t;
EOF

patch -p1 <<EOF
--- a/subversion/libsvn_subr/win32_xlate.c  2013-07-25 10:59:24.048322413 -0400
+++ b/subversion/libsvn_subr/win32_xlate.c  2013-07-25 11:00:13.571641225 -0400
@@ -41,6 +41,9 @@
 
 #include "win32_xlate.h"
 
+const IID IID_IMultiLanguage = {0x275c23e1,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+const CLSID CLSID_CMultiLanguage = {0x275c23e2,0x3747,0x11d0,{0x9f,0xea,0x00,0xaa,0x00,0x3f,0x86,0x46}};
+
 typedef struct win32_xlate_t
 {
   UINT from_page_id;
EOF

patch -p1 <<EOF
--- a/Makefile.in  2013-07-25 12:33:40.730131802 -0400
+++ b/Makefile.in  2013-07-25 12:33:43.720130557 -0400
@@ -187,6 +187,8 @@
 LINK = $(LIBTOOL) $(LTFLAGS) --mode=link $(CC) $(LT_LDFLAGS) $(CFLAGS) $(LDFLAGS) -rpath $(libdir)
 LINK_CXX = $(LIBTOOL) $(LTCXXFLAGS) --mode=link $(CXX) $(LT_LDFLAGS) $(CXXFLAGS) $(LDFLAGS) -rpath $(libdir)
 
+LINK_TESTS = $(filter-out -no-undefined,$(LINK))
+
 # special link rule for mod_dav_svn
 LINK_APACHE_MOD = $(LIBTOOL) $(LTFLAGS) --mode=link $(CC) $(LT_LDFLAGS) $(CFLAGS) $(LDFLAGS) -rpath $(APACHE_LIBEXECDIR) -avoid-version -module $(APACHE_LDFLAGS)
 
EOF

patch -p1 <<EOF
--- a/build.conf  2013-07-25 12:34:57.086766117 -0400
+++ b/build.conf  2013-07-25 12:35:02.733430345 -0400
@@ -564,6 +564,7 @@
 libs = libsvn_repos libsvn_fs libsvn_delta libsvn_subr aprutil apriconv apr
 msvc-static = yes
 undefined-lib-symbols = yes
+link-cmd = $(LINK_TESTS)
 
 # ----------------------------------------------------------------------------
 # Tests for libsvn_fs_base
@@ -574,6 +575,7 @@
 path = subversion/tests/libsvn_fs_base
 sources = fs-base-test.c
 install = bdb-test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_fs_base libsvn_delta
        libsvn_fs_util libsvn_subr apriconv apr
 
@@ -583,6 +585,7 @@
 path = subversion/tests/libsvn_fs_base
 sources = key-test.c
 install = bdb-test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs_base libsvn_subr apriconv apr 
 
 [strings-reps-test]
@@ -591,6 +594,7 @@
 path = subversion/tests/libsvn_fs_base
 sources = strings-reps-test.c
 install = bdb-test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_fs_base libsvn_delta
        libsvn_subr apriconv apr
 
@@ -600,6 +604,7 @@
 path = subversion/tests/libsvn_fs_base
 sources = changes-test.c
 install = bdb-test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_fs_base libsvn_delta
        libsvn_subr apriconv apr
 
@@ -611,6 +616,7 @@
 path = subversion/tests/libsvn_fs_fs
 sources = fs-pack-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_fs_fs libsvn_delta
        libsvn_subr apriconv apr
 
@@ -623,6 +629,7 @@
 path = subversion/tests/libsvn_fs
 sources = locks-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_delta libsvn_subr apriconv apr
 
 [fs-test]
@@ -631,6 +638,7 @@
 path = subversion/tests/libsvn_fs
 sources = fs-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_fs libsvn_delta
        libsvn_subr aprutil apriconv apr
 
@@ -643,6 +651,7 @@
 path = subversion/tests/libsvn_repos
 sources = repos-test.c dir-delta-editor.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_repos libsvn_fs libsvn_delta libsvn_subr apriconv apr
 
 # ----------------------------------------------------------------------------
@@ -654,6 +663,7 @@
 path = subversion/tests/libsvn_subr
 sources = auth-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr
 
 [cache-test]
@@ -662,6 +672,7 @@
 path = subversion/tests/libsvn_subr
 sources = cache-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [checksum-test]
@@ -670,6 +681,7 @@
 path = subversion/tests/libsvn_subr
 sources = checksum-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [compat-test]
@@ -678,6 +690,7 @@
 path = subversion/tests/libsvn_subr
 sources = compat-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [config-test]
@@ -686,6 +699,7 @@
 path = subversion/tests/libsvn_subr
 sources = config-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [dirent_uri-test]
@@ -694,6 +708,7 @@
 path = subversion/tests/libsvn_subr
 sources = dirent_uri-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [error-test]
@@ -702,6 +717,7 @@
 path = subversion/tests/libsvn_subr
 sources = error-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [hashdump-test]
@@ -710,6 +726,7 @@
 path = subversion/tests/libsvn_subr
 sources = hashdump-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [opt-test]
@@ -718,6 +735,7 @@
 path = subversion/tests/libsvn_subr
 sources = opt-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [mergeinfo-test]
@@ -726,6 +744,7 @@
 path = subversion/tests/libsvn_subr
 sources = mergeinfo-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [path-test]
@@ -734,6 +753,7 @@
 path = subversion/tests/libsvn_subr
 sources = path-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [revision-test]
@@ -742,6 +762,7 @@
 path = subversion/tests/libsvn_subr
 sources = revision-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apr
 
 [skel-test]
@@ -750,6 +771,7 @@
 path = subversion/tests/libsvn_subr
 sources = skel-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [stream-test]
@@ -758,6 +780,7 @@
 path = subversion/tests/libsvn_subr
 sources = stream-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [string-test]
@@ -766,6 +789,7 @@
 path = subversion/tests/libsvn_subr
 sources = string-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [time-test]
@@ -774,6 +798,7 @@
 path = subversion/tests/libsvn_subr
 sources = time-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [utf-test]
@@ -782,6 +807,7 @@
 path = subversion/tests/libsvn_subr
 sources = utf-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [target-test]
@@ -790,6 +816,7 @@
 path = subversion/tests/libsvn_subr
 sources = target-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 [translate-test]
@@ -798,6 +825,7 @@
 path = subversion/tests/libsvn_subr
 sources = translate-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_subr apriconv apr
 
 # ----------------------------------------------------------------------------
@@ -809,6 +837,7 @@
 path = subversion/tests/libsvn_delta
 sources = random-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_delta libsvn_subr apriconv apr
 
 [window-test]
@@ -817,6 +846,7 @@
 path = subversion/tests/libsvn_delta
 sources = window-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_delta libsvn_subr apriconv apr
 
 # ----------------------------------------------------------------------------
@@ -828,6 +858,7 @@
 path = subversion/tests/libsvn_client
 sources = client-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_delta libsvn_subr libsvn_client apriconv apr neon
 
 # ----------------------------------------------------------------------------
@@ -839,6 +870,7 @@
 path = subversion/tests/libsvn_diff
 sources = diff-diff3-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_diff libsvn_subr apriconv apr
 
 # ----------------------------------------------------------------------------
@@ -850,6 +882,7 @@
 path = subversion/tests/libsvn_ra_local
 sources = ra-local-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_ra_local libsvn_ra libsvn_fs libsvn_delta libsvn_subr
        apriconv apr neon
 
@@ -862,6 +895,7 @@
 path = subversion/tests/libsvn_wc
 sources = tree-conflict-data-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_test libsvn_wc libsvn_subr apriconv apr
 
 # ----------------------------------------------------------------------------
@@ -876,6 +910,7 @@
 path = subversion/tests/libsvn_delta
 sources = svndiff-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_delta libsvn_subr apriconv apr
 testing = skip
 
@@ -885,6 +920,7 @@
 path = subversion/tests/libsvn_delta
 sources = vdelta-test.c
 install = test
+link-cmd = $(LINK_TESTS)
 libs = libsvn_delta libsvn_subr apriconv apr
 testing = skip
 
EOF

patch -p1 <<EOF
--- a/subversion/tests/libsvn_subr/dirent_uri-test.c  2013-07-25 12:02:16.200182785 -0400
+++ b/subversion/tests/libsvn_subr/dirent_uri-test.c  2013-07-25 12:02:18.320182516 -0400
@@ -19,7 +19,7 @@
 #include <stdio.h>
 #include <string.h>
 
-#ifdef _MSC_VER
+#ifdef __MSVCRT__
 #include <direct.h>
 #define getcwd _getcwd
 #define getdcwd _getdcwd
EOF

make fsmod-lib ramod-lib lib bin

make install

i486-mingw32-strip $BUILD_DIR/env/*.dll
i486-mingw32-strip $BUILD_DIR/env/*.exe

mkdir $BUILD_DIR/build/1.6/
cp $BUILD_DIR/env/bin/libsvn*.dll $BUILD_DIR/build/1.6/
cp $BUILD_DIR/env/bin/svn.exe $BUILD_DIR/build/1.6/
rm $BUILD_DIR/env/bin/libsvn*
rm $BUILD_DIR/env/bin/svn*


cp $BUILD_DIR/env/bin/*.dll $BUILD_DIR/build
