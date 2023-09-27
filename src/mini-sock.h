#ifndef _platform_socket_h_
#define _platform_socket_h_

#ifndef OS_WINDOWS
#ifdef _WIN32
#define OS_WINDOWS
#endif
#endif

#if defined(OS_WINDOWS)
#include <Winsock2.h>
#include <WS2tcpip.h>
#include <ws2ipdef.h>

#ifndef OS_SOCKET_TYPE
typedef SOCKET	socket_t;
typedef WSABUF	socket_bufvec_t;
#define OS_SOCKET_TYPE
#endif /* OS_SOCKET_TYPE */

#define socket_invalid	INVALID_SOCKET
#define socket_error	SOCKET_ERROR
#else
#include <sys/time.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <poll.h>

#ifndef OS_SOCKET_TYPE
typedef int socket_t;
typedef struct iovec socket_bufvec_t;
#define OS_SOCKET_TYPE
#endif /* OS_SOCKET_TYPE */

#define socket_invalid -1
#define socket_error -1
#endif


#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#ifndef IN
#define IN 
#endif

#ifndef OUT
#define OUT
#endif

#ifndef INOUT
#define INOUT
#endif

#define SOCKET_ADDRLEN INET6_ADDRSTRLEN

//////////////////////////////////////////////////////////////////////////
///
/// socket read/write
/// 
//////////////////////////////////////////////////////////////////////////
static inline int socket_send(IN socket_t sock, IN const void* buf, IN size_t len, IN int flags)
{
#if defined(OS_WINDOWS)
	return send(sock, (const char*)buf, (int)len, flags);
#else
	return (int)send(sock, buf, len, flags);
#endif
}

static inline int socket_recv(IN socket_t sock, OUT void* buf, IN size_t len, IN int flags)
{
#if defined(OS_WINDOWS)
	return recv(sock, (char*)buf, (int)len, flags);
#else
	return (int)recv(sock, buf, len, flags);
#endif
}


//////////////////////////////////////////////////////////////////////////
///
/// socket operation
/// 
//////////////////////////////////////////////////////////////////////////
static inline int socket_connect(IN socket_t sock, IN const struct sockaddr* addr, IN socklen_t addrlen)
{
	return connect(sock, addr, addrlen);
}

static inline int socket_bind(IN socket_t sock, IN const struct sockaddr* addr, IN socklen_t addrlen)
{
	return bind(sock, addr, addrlen);
}

static inline int socket_listen(IN socket_t sock, IN int backlog)
{
	return listen(sock, backlog);
}

static inline socket_t socket_accept(IN socket_t sock, OUT struct sockaddr_storage* addr, OUT socklen_t* addrlen)
{
	*addrlen = sizeof(struct sockaddr_storage);
	return accept(sock, (struct sockaddr*)addr, addrlen);
}

//////////////////////////////////////////////////////////////////////////
///
/// socket create/close 
/// 
//////////////////////////////////////////////////////////////////////////
static inline int socket_init(void)
{
#if defined(OS_WINDOWS)
	WORD wVersionRequested;
	WSADATA wsaData;
	
	wVersionRequested = MAKEWORD(2, 2);
	return WSAStartup(wVersionRequested, &wsaData);
#else
	return 0;
#endif
}

static inline int socket_cleanup(void)
{
#if defined(OS_WINDOWS)
	return WSACleanup();
#else
	return 0;
#endif
}

static inline int socket_geterror(void)
{
#if defined(OS_WINDOWS)
	return WSAGetLastError();
#else
	return errno;
#endif
}

static inline socket_t socket_tcp(void)
{
	return socket(PF_INET, SOCK_STREAM, 0);
}

static inline int socket_shutdown(socket_t sock, int flag)
{
	return shutdown(sock, flag);
}

static inline int socket_close(socket_t sock)
{
#if defined(OS_WINDOWS)
	// MSDN:
	// If closesocket fails with WSAEWOULDBLOCK the socket handle is still valid, 
	// and a disconnect is not initiated. The application must call closesocket again to close the socket. 
	return closesocket(sock);
#else
	return close(sock);
#endif
}


static inline int socket_addr_setport(IN struct sockaddr* sa, IN socklen_t salen, u_short port)
{
	if (AF_INET == sa->sa_family)
	{
		struct sockaddr_in* in = (struct sockaddr_in*)sa;
		assert(sizeof(struct sockaddr_in) == salen);
		in->sin_port = htons(port);
	}
	else if (AF_INET6 == sa->sa_family)
	{
		struct sockaddr_in6* in6 = (struct sockaddr_in6*)sa;
		assert(sizeof(struct sockaddr_in6) == salen);
		in6->sin6_port = htons(port);
	}
	else
	{
		assert(0);
		return -1;
	}

	(void)salen;
	return 0;
}


static inline int socket_addr_from_ipv4(OUT struct sockaddr_in* addr4, IN const char* ipv4_or_dns, IN u_short port)
{
	int r;
	char portstr[16];
	struct addrinfo hints, *addr;
	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_INET;
//	hints.ai_flags = AI_ADDRCONFIG;
	snprintf(portstr, sizeof(portstr), "%hu", port);
	r = getaddrinfo(ipv4_or_dns, portstr, &hints, &addr);
	if (0 != r)
		return r;

	// fixed ios getaddrinfo don't set port if node is ipv4 address
	socket_addr_setport(addr->ai_addr, (socklen_t)addr->ai_addrlen, port);
	assert(sizeof(struct sockaddr_in) == addr->ai_addrlen);
	memcpy(addr4, addr->ai_addr, addr->ai_addrlen);
	freeaddrinfo(addr);
	return 0;
}

static inline int socket_addr_from_ipv6(OUT struct sockaddr_in6* addr6, IN const char* ipv6_or_dns, IN u_short port)
{
	int r;
	char portstr[16];
	struct addrinfo hints, *addr;
	memset(&hints, 0, sizeof(hints));
	hints.ai_family = AF_INET6;
	hints.ai_flags = AI_V4MAPPED /*| AI_ADDRCONFIG*/; // AI_ADDRCONFIG linux "ff00::" return -2
	snprintf(portstr, sizeof(portstr), "%hu", port);
	r = getaddrinfo(ipv6_or_dns, portstr, &hints, &addr);
	if (0 != r)
		return r;

	// fixed ios getaddrinfo don't set port if node is ipv4 address
	socket_addr_setport(addr->ai_addr, (socklen_t)addr->ai_addrlen, port);
	assert(sizeof(struct sockaddr_in6) == addr->ai_addrlen);
	memcpy(addr6, addr->ai_addr, addr->ai_addrlen);
	freeaddrinfo(addr);
	return 0;
}


static inline int socket_addr_from(OUT struct sockaddr_storage* ss, OUT socklen_t* len, IN const char* ipv4_or_ipv6_or_dns, IN u_short port)
{
	int r;
	char portstr[16];
	struct addrinfo *addr;
	snprintf(portstr, sizeof(portstr), "%hu", port);
	r = getaddrinfo(ipv4_or_ipv6_or_dns, portstr, NULL, &addr);
	if (0 != r)
		return r;

	// fixed ios getaddrinfo don't set port if node is ipv4 address
	socket_addr_setport(addr->ai_addr, (socklen_t)addr->ai_addrlen, port);
	assert((size_t)addr->ai_addrlen <= sizeof(struct sockaddr_storage));
	memcpy(ss, addr->ai_addr, addr->ai_addrlen);
	if(len) *len = (socklen_t)addr->ai_addrlen;
	freeaddrinfo(addr);
	return 0;
}

static inline int socket_addr_to(IN const struct sockaddr* sa, IN socklen_t salen, OUT char ip[SOCKET_ADDRLEN], OUT u_short* port)
{
	if (AF_INET == sa->sa_family)
	{
		struct sockaddr_in* in = (struct sockaddr_in*)sa;
		assert(sizeof(struct sockaddr_in) == salen);
		inet_ntop(AF_INET, &in->sin_addr, ip, SOCKET_ADDRLEN);
		if(port) *port = ntohs(in->sin_port);
	}
	else if (AF_INET6 == sa->sa_family)
	{
		struct sockaddr_in6* in6 = (struct sockaddr_in6*)sa;
		assert(sizeof(struct sockaddr_in6) == salen);
		inet_ntop(AF_INET6, &in6->sin6_addr, ip, SOCKET_ADDRLEN);
		if (port) *port = ntohs(in6->sin6_port);
	}
	else
	{
		return -1; // unknown address family
	}

	(void)salen;
	return 0;
}

//////////////////////////////////////////////////////////////////////////
///
/// socket options
/// 
//////////////////////////////////////////////////////////////////////////

static inline int socket_setopt_bool(IN socket_t sock, IN int optname, IN int enable)
{
#if defined(OS_WINDOWS)
	BOOL v = enable ? TRUE : FALSE;
	return setsockopt(sock, SOL_SOCKET, optname, (const char*)&v, sizeof(v));
#else
	return setsockopt(sock, SOL_SOCKET, optname, &enable, sizeof(enable));
#endif
}

static inline int socket_setreuseaddr(IN socket_t sock, IN int enable)
{
	// https://stackoverflow.com/questions/14388706/socket-options-so-reuseaddr-and-so-reuseport-how-do-they-differ-do-they-mean-t
	// https://www.cnblogs.com/xybaby/p/7341579.html
	// Windows: SO_REUSEADDR = SO_REUSEADDR + SO_REUSEPORT
	return socket_setopt_bool(sock, SO_REUSEADDR, enable);
}

static inline int socket_setreuseport(IN socket_t sock, IN int enable)
{
#if defined(OS_WINDOWS)
	// Windows: SO_REUSEADDR = SO_REUSEADDR + SO_REUSEPORT
	return socket_setopt_bool(sock, SO_REUSEADDR, enable);
#elif defined(SO_REUSEPORT)
	return socket_setopt_bool(sock, SO_REUSEPORT, enable);	
#else
	return -1;
#endif
}


// 1-cork, 0-uncork
static inline int socket_setcork(IN socket_t sock, IN int cork)
{
#if defined(TCP_CORK)
	//return setsockopt(sock, IPPROTO_TCP, TCP_NOPUSH, &cork, sizeof(cork));
    return setsockopt(sock, IPPROTO_TCP, TCP_CORK, &cork, sizeof(cork));
#else
	(void)sock, (void)cork;
	return -1;
#endif
}

static inline int socket_setnonblock(IN socket_t sock, IN int noblock)
{
	// 0-block, 1-no-block
#if defined(OS_WINDOWS)
	u_long arg = noblock;
	return ioctlsocket(sock, FIONBIO, &arg);
#else
	// http://stackoverflow.com/questions/1150635/unix-nonblocking-i-o-o-nonblock-vs-fionbio
	// Prior to standardization there was ioctl(...FIONBIO...) and fcntl(...O_NDELAY...) ...
	// POSIX addressed this with the introduction of O_NONBLOCK.
	int flags = fcntl(sock, F_GETFL, 0);
	return fcntl(sock, F_SETFL, noblock ? (flags | O_NONBLOCK) : (flags & ~O_NONBLOCK));
	//return ioctl(sock, FIONBIO, &noblock);
#endif
}

static inline int socket_setnondelay(IN socket_t sock, IN int nodelay)
{
	// 0-delay(enable the Nagle algorithm)
	// 1-no-delay(disable the Nagle algorithm)
	// http://linux.die.net/man/7/tcp
	return setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, (const char*)&nodelay, sizeof(nodelay));
}

static inline int socket_setipv6only(IN socket_t sock, IN int ipv6_only)
{
	// Windows Vista or later: default 1
	// https://msdn.microsoft.com/en-us/library/windows/desktop/ms738574%28v=vs.85%29.aspx
	// Linux 2.4.21 and 2.6: /proc/sys/net/ipv6/bindv6only defalut 0
	// http://www.man7.org/linux/man-pages/man7/ipv6.7.html
	return setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY, (const char*)&ipv6_only, sizeof(ipv6_only));
}

#endif