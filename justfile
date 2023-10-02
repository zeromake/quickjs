set windows-powershell := true

QJSC := 'xmake r qjsc'
QJS := 'xmake r qjs'
RUN_TEST262 := 'xmake r run-test262'
GENERATE_DIR := 'build/generate'
BUILD_COMMAND := 'xmake b -vD'
MODE := 'debug'
# [coreutils](https://github.com/uutils/coreutils)
# [busybox](https://github.com/rmyorston/busybox-w32)
CUP := if os() == 'windows' {'busybox '} else {''}

init:
	@{{CUP}}mkdir -p {{GENERATE_DIR}}
	@{{CUP}}touch {{GENERATE_DIR}}/qjscalc.c
	@{{CUP}}touch {{GENERATE_DIR}}/repl.c
	@{{CUP}}touch {{GENERATE_DIR}}/tsc.c
	@{{CUP}}touch {{GENERATE_DIR}}/quickjs.def
	@{{CUP}}touch {{GENERATE_DIR}}/quickjs.map

#  -p mingw --mingw=D:\Scoop\Program\llvm-mingw
config: init
	xmake f -m {{MODE}} -c -y --bignum=y --js-debugger=y

generate_export:
	xmake lua .\scripts\export_list.lua

quickjs: config generate_export
	{{BUILD_COMMAND}} quickjs

qjsc: quickjs
	{{BUILD_COMMAND}} qjsc

generate_qjscalc: qjsc
	{{QJSC}} -fbignum -c -o {{GENERATE_DIR}}/qjscalc.c src/qjscalc.js

generate_repl: qjsc
	{{QJSC}} -c -o {{GENERATE_DIR}}/repl.c -m src/repl.js

generate_tsc:
	xmake lua scripts/tsc.lua
	{{QJSC}} -e -o {{GENERATE_DIR}}/tsc.c build/extract/ts/package/lib/tsc-quickjs.js

qjs: quickjs generate_qjscalc generate_repl
	{{BUILD_COMMAND}} qjs

tsc: generate_tsc
	{{BUILD_COMMAND}} tsc

bjson: quickjs
	{{BUILD_COMMAND}} tests/bjson

test: qjs bjson
	{{QJS}} tests/test_language.js
	{{QJS}} tests/test_loop.js
	{{QJS}} tests/test_std.js
	{{QJS}} --bignum tests/test_op_overloading.js
	{{QJS}} --bignum tests/test_bignum.js
	{{QJS}} --qjscalc tests/test_qjscalc.js
	{{QJS}} tests/test_builtin.js
	{{QJS}} tests/test_closure.js
	{{QJS}} --bignum tests/test_bjson.js
	# {{QJS}} tests/test_worker.js

run_test262: quickjs
	{{BUILD_COMMAND}} run-test262

test262:
	{{RUN_TEST262}} -m -c tests/test262/test262.conf
