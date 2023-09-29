set windows-powershell := true

QJSC := 'xmake r qjsc'
QJS := 'xmake r qjs'
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

# -p mingw --mingw=D:\Scoop\Program\llvm-mingw
config: init
	xmake f -m {{MODE}} -c -y --bignum=y --js-debugger=y

qjsc: config
	{{BUILD_COMMAND}} qjsc

generate_qjscalc: qjsc
	{{QJSC}} -fbignum -c -o {{GENERATE_DIR}}/qjscalc.c src/qjscalc.js

generate_repl: qjsc
	{{QJSC}} -c -o {{GENERATE_DIR}}/repl.c -m src/repl.js

generate_tsc:
	xmake lua scripts/tsc.lua
	{{QJSC}} -e -o {{GENERATE_DIR}}/tsc.c build/extract/ts/package/lib/tsc-quickjs.js

qjs: config generate_qjscalc generate_repl
	{{BUILD_COMMAND}} qjs

tsc: generate_tsc
	{{BUILD_COMMAND}} tsc

test: qjs
	{{QJS}} tests/test_language.js
	{{QJS}} tests/test_loop.js
	{{QJS}} tests/test_std.js
	{{QJS}} --bignum tests/test_op_overloading.js
	{{QJS}} --bignum tests/test_bignum.js
	{{QJS}} --qjscalc tests/test_qjscalc.js
	{{QJS}} tests/test_builtin.js
	{{QJS}} tests/test_closure.js
	# {{QJS}} tests/test_worker.js
