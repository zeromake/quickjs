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

## Todo

- [ ] [js-tobigint64-overflow patch](https://github.com/theduke/quickjs-rs/blob/master/libquickjs-sys/embed/patches/js-tobigint64-overflow.patch) does this patch need to be applied
