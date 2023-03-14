#include "quickjs-debugger.h"
#ifdef _WIN32
#define OS_WINDOWS
#endif
#include "sock.h"
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

#define debugf(...) printf(__VA_ARGS__);fflush(stdout);
#ifdef NDEBUG
#define js_assert(expression) if (!expression) {\
    JS_ASSERT_PRINT;\
    return JS_ASSERT_RET;\
}
#else
#define js_assert(expression) assert(expression)
#endif

struct js_transport_data {
    socket_t handle;
} js_transport_data;


static size_t js_transport_read(void *udata, char *buffer, size_t length) {
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (!data->handle)
        return -1;

    if (length == 0)
        return -2;

    if (buffer == NULL)
        return -3;

    int ret  = socket_recv(data->handle, (void *)buffer, length, 0);

    // debugf("socket_recv: %d %d\n", ret, error_no);
    if (ret < 0)
        return -4;

    if (ret == 0)
        return -5;

    if (ret > length)
        return -6;

    // buffer[length] = 0;
    // debugf("js_transport_read: %s\n", buffer);
    return ret;
}


static size_t js_transport_write(void *udata, const char *buffer, size_t length) {
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (!data->handle)
        return -1;

    if (length == 0)
        return -2;

    if (buffer == NULL)
        return -3;
    // debugf("js_transport_write: %s\n", buffer);
    int ret = socket_send(data->handle, (const void *) buffer, length, 0);
    // debugf("js_transport_write done: %d\n", socket_geterror());
    if (ret <= 0 || ret > length)
        return -4;

    return ret;
}


static size_t js_transport_peek(void *udata) {
#ifdef _WIN32
    WSAPOLLFD  fds[1];
    int poll_rc;

    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle == socket_invalid)
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
#else
    struct pollfd fds[1];
    int poll_rc;

    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (!data->handle)
        return -1;

    fds[0].fd = data->handle;
    fds[0].events = POLLIN;
    fds[0].revents = 0;

    poll_rc = poll(fds, 1, 0);
    if (poll_rc < 0)
        return -2;
    if (poll_rc > 1)
        return -3;
    // no data
    if (poll_rc == 0)
        return 0;
    // has data
    return 1;
#endif
}


static void js_transport_close(JSRuntime* rt, void *udata) {
    // debugf("js_transport_close\n");
    struct js_transport_data* data = (struct js_transport_data *)udata;
    if (data->handle == socket_invalid)
        return;
    socket_close(data->handle);
    socket_cleanup();
    free(udata);
}

#define JS_ASSERT_PRINT fprintf(stderr, "parse addr assert -> %s:%d\n", __FILE__, __LINE__)
#define JS_ASSERT_RET -1

static int js_debugger_parse_sockaddr(const char* address, struct sockaddr_in *addr) {
    char* port_string = strstr(address, ":");
    js_assert(port_string);

    int port = atoi(port_string + 1);
    js_assert(port);

    char host_string[256];// = "127.0.0.1";
    strcpy(host_string, address);
    host_string[port_string - address] = 0;
    return socket_addr_from_ipv4(addr, host_string, port);
}


#define JS_ASSERT_PRINT fprintf(stdout, "client connect assert -> %s:%d\n", __FILE__, __LINE__);fflush(stdout)
#define JS_ASSERT_RET
void js_debugger_connect(JSContext *ctx, const char *address) {
    js_assert(!socket_init());

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    int ret = js_debugger_parse_sockaddr(address, &addr);
    js_assert(!ret);
    socket_t client = socket_tcp();
    js_assert(client);
    ret = socket_connect(client, (const struct sockaddr*)&addr, sizeof(addr));
    js_assert(!ret);

    struct js_transport_data *data = (struct js_transport_data *)malloc(sizeof(struct js_transport_data));
    memset(data, 0, sizeof(js_transport_data));
    data->handle = client;
    js_debugger_attach(ctx, js_transport_read, js_transport_write, js_transport_peek, js_transport_close, data);
}

#define JS_ASSERT_PRINT fprintf(stdout, "server connect assert -> %s:%d\n", __FILE__, __LINE__);fflush(stdout)

void js_debugger_wait_connection(JSContext *ctx, const char* address) {
    js_assert(!socket_init());
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    int ret = js_debugger_parse_sockaddr(address, &addr);
    socket_t server = socket_tcp();
    js_assert(server);
    js_assert(!socket_setreuseaddr(server, 1));
    js_assert(!socket_bind(server, (const struct sockaddr*)&addr, sizeof(addr)));
    js_assert(!socket_listen(server, 1));

    struct sockaddr_storage client_addr;
    socklen_t client_addr_size;
    socket_t client = socket_accept(server, &client_addr, &client_addr_size);
    socket_close(server);
    js_assert(client);

    struct js_transport_data *data = (struct js_transport_data *)malloc(sizeof(struct js_transport_data));
    memset(data, 0, sizeof(js_transport_data));
    data->handle = client;
    js_debugger_attach(ctx, js_transport_read, js_transport_write, js_transport_peek, js_transport_close, data);
}