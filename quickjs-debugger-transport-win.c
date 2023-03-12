#include "quickjs-debugger.h"

#ifndef _WIN32
#include <unistd.h>
#else
#ifdef _MSC_VER
#if defined(_WIN64)
typedef unsigned __int64    ssize_t;
#elif defined(_WIN32)
typedef _W64 unsigned int   ssize_t;
#endif
#endif
#endif
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <winsock2.h>
#include <ws2tcpip.h>

#define debugf(msg) printf(msg);\
fflush(stdout);

struct js_transport_data {
    int handle;
} js_transport_data;

static size_t js_transport_read(void *udata, char *buffer, size_t length) {
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle <= 0)
        return -1;

    if (length == 0)
        return -2;

    if (buffer == NULL)
        return -3;

    buffer[length] = 0;

    //ssize_t ret = read(data->handle, (void *)buffer, length);
	ssize_t ret = recv( data->handle, (void*)buffer, length, 0);

    if (ret == SOCKET_ERROR )
        return -4;

    if (ret == 0)
        return -5;

    if (ret > length)
        return -6;

    return ret;
}

static size_t js_transport_write(void *udata, const char *buffer, size_t length) {
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle <= 0)
        return -1;

    if (length == 0)
        return -2;

    if (buffer == NULL) {
        return -3;
	}

    //size_t ret = write(data->handle, (const void *) buffer, length);
	size_t ret = send( data->handle, (const void *) buffer, length, 0);
    if (ret <= 0 || ret > (ssize_t) length)
        return -4;

    return ret;
}

static size_t js_transport_peek(void *udata) {
    WSAPOLLFD  fds[1];
    int poll_rc;

    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle <= 0)
        return -1;

    fds[0].fd = data->handle;
    fds[0].events = POLLIN;
    fds[0].revents = 0;

    poll_rc = WSAPoll(fds, 1, 0);
    if (poll_rc < 0)
        return -2;
    if (poll_rc > 1)
        return -3;
    // no data
    if (poll_rc == 0)
        return 0;
    // has data
    return 1;
}

static void js_transport_close(JSRuntime* rt, void *udata) {
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle <= 0)
        return;

    closesocket(data->handle);
	data->handle = 0;

    free(udata);

	WSACleanup();
}

void js_debugger_connect(JSContext *ctx, const char *address) {
	WSADATA wsaData;
	WSAStartup(MAKEWORD(2, 2), &wsaData);
    char* port_string = strstr(address, ":");
    assert(port_string);

    char host_string[256];
    strcpy(host_string, address);
    host_string[port_string - address] = 0;

    struct addrinfo hints;
	struct addrinfo* result = NULL;

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
	hints.ai_protocol = IPPROTO_TCP;
	hints.ai_socktype = SOCK_STREAM;

    int ret = getaddrinfo(host_string, port_string+1, &hints, &result);
    assert(!ret);
    int client = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    assert(client != INVALID_SOCKET);

    int flags = 1;
    assert(!setsockopt(client, SOL_SOCKET, SO_KEEPALIVE, (void *)&flags, sizeof(flags)));

	//__asm__ volatile("int $0x03");
	assert(!connect(client, result->ai_addr, result->ai_addrlen));

    freeaddrinfo(result);

    struct js_transport_data *data = (struct js_transport_data *)malloc(sizeof(struct js_transport_data));
    data->handle = client;
    js_debugger_attach(ctx, js_transport_read, js_transport_write, js_transport_peek, js_transport_close, data);
}


void js_debugger_wait_connection(JSContext *ctx, const char* address) {
	WSADATA wsaData;
	WSAStartup(MAKEWORD(2, 2), &wsaData);

    struct addrinfo hints;
    PADDRINFOA result = NULL;
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	hints.ai_flags = AI_PASSIVE;

    char* port_string = strstr(address, ":");
    assert(port_string);

    assert(!getaddrinfo(NULL, port_string, &hints, &result));

    SOCKET server = socket(
        result->ai_family,
        result->ai_socktype,
        result->ai_protocol);
    assert(server != INVALID_SOCKET);

    assert(bind(server, result->ai_addr, (int)result->ai_addrlen) != SOCKET_ERROR);

    freeaddrinfo(result);

    assert(listen(server, SOMAXCONN) != SOCKET_ERROR);
    SOCKET client = accept(server, NULL, NULL);
    closesocket(server);
    assert(client != INVALID_SOCKET);
    struct js_transport_data *data = (struct js_transport_data *)malloc(
        sizeof(struct js_transport_data)
    );
    memset(data, 0, sizeof(js_transport_data));
    data->handle = client;
    js_debugger_attach(
        ctx,
        js_transport_read,
        js_transport_write,
        js_transport_peek,
        js_transport_close,
        data);
}