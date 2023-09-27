set windows-powershell := true

QJSC := 'xmake r qjsc'
GENERATE_DIR := 'build/generate'
BUILD_COMMAND := 'xmake b -v'
# [coreutils](https://github.com/uutils/coreutils)
# [busybox](https://github.com/rmyorston/busybox-w32)
CUP := if os() == 'windows' {'busybox '} else {''}

init:
	@{{CUP}}mkdir -p {{GENERATE_DIR}}
	@{{CUP}}touch {{GENERATE_DIR}}/qjscalc.c
	@{{CUP}}touch {{GENERATE_DIR}}/repl.c
	@{{CUP}}touch {{GENERATE_DIR}}/tsc.c

config: init
	xmake f -c -y --bignum=y --js-debugger=y

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

generate_unicode:
	{{CUP}}echo '1'
