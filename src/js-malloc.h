
#ifndef JS_MALLOC_H
#define JS_MALLOC_H

#if defined(__APPLE__)
#include <malloc/malloc.h>
#elif defined(__ANDROID__)
#include <dlmalloc.h>
#elif defined(__linux__) || defined(__CYGWIN__) || defined(_MSC_VER)
#include <malloc.h>
#elif defined(__FreeBSD__)
#include <malloc_np.h>
#endif

#if ENABLE_MI_MALLOC
    #include <mimalloc.h>
    #define js_builtin_malloc mi_malloc
    #define js_builtin_free mi_free
    #define js_builtin_realloc mi_realloc
    #define js_builtin_malloc_size mi_usable_size
#else
    #define js_builtin_malloc malloc
    #define js_builtin_free free
    #define js_builtin_realloc realloc
#if defined(__APPLE__)
    #define js_builtin_malloc_size malloc_size
#elif defined(_WIN32)
    #define js_builtin_malloc_size _msize
#elif defined(EMSCRIPTEN)
    #define js_builtin_malloc_size(ptr) 0
#elif defined(__linux__)
    #define js_builtin_malloc_size malloc_usable_size
#else
    #define js_builtin_malloc_size malloc_usable_size
#endif
#endif

#endif
