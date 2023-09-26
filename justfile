QJSC := 'xmake r qjsc'
GENERATE_DIR := 'build/generate'
BUILD_COMMAND := 'xmake b -v'

init:
	touch {{GENERATE_DIR}}/qjscalc.c
	touch {{GENERATE_DIR}}/repl.c
	touch {{GENERATE_DIR}}/tsc.c
	mkdir -p build/generate

config: init
	xmake f -c -y --bignum=y --js-debugger=y

qjsc: config
	{{BUILD_COMMAND}} qjsc

generate_qjscalc: qjsc
	{{QJSC}} -fbignum -c -o {{GENERATE_DIR}}/qjscalc.c qjscalc.js

generate_repl: qjsc
	{{QJSC}} -c -o {{GENERATE_DIR}}/repl.c -m repl.js

generate_tsc:
	xmake lua tsc.lua
	{{QJSC}} -e -o {{GENERATE_DIR}}/tsc.c build/extract/ts/package/lib/tsc-quickjs.js

qjs: config generate_qjscalc generate_repl
	{{BUILD_COMMAND}} qjs

tsc:
	{{BUILD_COMMAND}} tsc

generate_unicode:
	echo '1'
