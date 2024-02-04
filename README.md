# quickjs

QuickJS is a small and embeddable Javascript engine. It supports the ES2020 specification including modules, asynchronous generators, proxies and BigInt.

It optionally supports mathematical extensions such as big decimal floating point numbers (BigDecimal), big binary floating point numbers (BigFloat) and operator overloading. 

## this repo change

- [x] migrate to xmake build
- [x] support msvc build (use [skeeto-getopt](https://github.com/skeeto/getopt), [simple-stdatomic](https://github.com/zenny-chen/simple-stdatomic-for-VS-Clang), [pthread-win32](https://github.com/GerHobbelt/pthread-win32))
- [x] support msvc bigint build (msvc not has int128, use int64)
- [ ] support msvc quickjs-libc
    - [x] os.lstat
    - [x] os.readdir
    - [x] os.issymlink
    - [x] os.symlink (copy from libuv code)
    - [x] os.pipe
    - [x] add `os.arch` const string
    - [x] js_module_loader_so use [dlfcn-win32](https://github.com/dlfcn-win32/dlfcn-win32) support dll
- [x] support [vscode debugger](https://github.com/koush/vscode-quickjs-debug)
    - [x] support windows vscode debugger breakpoint file path is to lowercase and `\` replace to `/`
- [ ] apply [pr](https://github.com/bellard/quickjs/pull)
    - [x] [windows support](https://github.com/bellard/quickjs/pull/51), [cross platform](https://github.com/bellard/quickjs/pull/49)
    - [x] [function line pc2line table](https://github.com/bellard/quickjs/pull)
    - [x] [not a function error format var_name](https://github.com/bellard/quickjs/pull/117)
- [ ] synchronize upstream changes [bellard/quickjs](https://github.com/bellard/quickjs)
    - [x] self project is init by [2021-03-27 release](https://github.com/bellard/quickjs/commit/b5e62895c619d4ffc75c9d822c8d85f1ece77e5b)
    - [x] upgrade [export JS_GetModuleNamespace (github issue #34)](https://github.com/bellard/quickjs/commit/c6cc6a9a5e420fa2707e828da23d131d2bf170f7)
    - [x] upgrade [avoid using INT64_MAX in double comparisons because it cannot be exactly represented as a double (bnoordhuis)](https://github.com/bellard/quickjs/commit/6f480abbc8b2abe91fcc0fa58aa07c367e1dcb36)
- [ ] synchronize upstream changes [openwebf/quickjs](https://github.com/openwebf/quickjs)
    - [x] [feat: add ENABLE_MI_MALLOC to on/off mimalloc support](https://github.com/openwebf/quickjs/commit/1f8dbca627728adff68f16155f3e5514a98ff1bd)

## Todo

- [ ] [js-tobigint64-overflow patch](https://github.com/theduke/quickjs-rs/blob/master/libquickjs-sys/embed/patches/js-tobigint64-overflow.patch) does this patch need to be applied
