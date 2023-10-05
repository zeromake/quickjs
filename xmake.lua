add_rules("mode.debug", "mode.release")

option("js-debugger")
    set_default(false)
    set_showmenu(true)
option_end()

option("bignum")
    set_default(true)
    set_showmenu(true)
option_end()

set_rundir("$(projectdir)")
add_includedirs("src")
add_repositories("zeromake https://github.com/zeromake/xrepo.git")

if is_plat("windows") then
    add_cxflags("/utf-8")
elseif is_plat("mingw") then
    add_ldflags("-pthread")
    add_ldflags("-static")
elseif is_plat('android', 'iphoneos') then
    add_ldflags("-pthread")
end

local version = "2023-09-27"
add_defines(
    format("CONFIG_VERSION=\"%s\"", version),
    "_GNU_SOURCE=1"
)

add_defines("CONFIG_DIRECT_DISPATCH="..(is_plat("windows") and "0" or "1"))
add_defines("CONFIG_LOADER_OS_ARCH_SO=1")

package("skeeto-getopt")
    set_urls("https://github.com/skeeto/getopt/archive/4e618ef782dc80b2cf0307ea74b68e6a62b025de.zip")
    add_versions("latest", "a3d322832f10fa0023d9e1041bbda98e0da5d6ca3d86e9848a1ab7054f4252e3")
    on_install(function (package) 
        os.cp("*.h", package:installdir("include"))
    end)
package_end()

package("simple-stdatomic")
    set_urls("https://github.com/zenny-chen/simple-stdatomic-for-VS-Clang/archive/refs/heads/master.zip")
    add_versions("latest", "574495c4cb587d9813b03ce1251a024fda5ac3c07918190ebedbad06303c6d0d")
    on_install(function (package)
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")
if is_plat("windows") then
    add_cxflags("/utf-8")
end
target("simple-stdatomic")
    set_kind("$(kind)")
    add_files("stdatomic.c")
    add_headerfiles("stdatomic.h")
]])
    import("package.tools.xmake").install(package, {})
    end)
package_end()

package("pthread-win32")
    set_urls("https://github.com/GerHobbelt/pthread-win32/archive/a89bf2154a28113a7373e25fe2729dee4e004385.zip")
    add_versions("latest", "a30f28f13aa1c932134abfa45a87f53ea9427dc151ebf02f049d7b08406da9bc")
    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))

        import("package.tools.cmake").install(package, configs)
    end)
package_end()

package("dlfcn-win32")
    set_urls("https://github.com/dlfcn-win32/dlfcn-win32/archive/refs/tags/v$(version).tar.gz")
    add_versions("1.3.1", "f7248a8baeb79d9bcd5f702cc08a777431708758e70d1730b59674c5e795e88a")
    on_install(function (package)
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")
if is_plat("windows") then
    add_cxflags("/utf-8")
end
target("dlfcn-win32")
    set_kind("$(kind)")
    add_files("src/dlfcn.c")
    add_headerfiles("src/dlfcn.h")
]])
    import("package.tools.xmake").install(package, {})
    end)
package_end()

if is_plat("windows") then
    add_requires("skeeto-getopt", "simple-stdatomic", "pthread-win32", "dlfcn-win32")
elseif is_plat("mingw") then
    add_requires("dlfcn-win32")
end

local function use_packages()
    if is_plat("windows") then
        add_packages("skeeto-getopt", "simple-stdatomic", "pthread-win32", "dlfcn-win32")
    elseif is_plat("mingw") then
        add_packages("dlfcn-win32")
    elseif is_plat("android", "iphoneos") then
    else
        add_syslinks("m", "dl", "pthread")
    end
    if is_plat("windows", "mingw") and get_config("js-debugger") then
        add_syslinks("ws2_32")
    end
    if get_config("bignum") then
        add_defines("CONFIG_BIGNUM=1")
    end
    if get_config("js-debugger") then
        add_defines("CONFIG_DEBUGGER=1")
    end
end

target("quickjs")
    set_kind("$(kind)")
    use_packages()
    add_files(
        "src/quickjs.c",
        "src/libregexp.c",
        "src/libunicode.c",
        "src/cutils.c",
        "src/quickjs-libc.c"
    )
    if is_plat("windows", "mingw") then
        add_files("build/generate/quickjs.def")
    else
        add_files("build/generate/quickjs.map")
    end
    if get_config("bignum") then
        add_files("src/libbf.c")
    end
    if get_config("js-debugger") then
        add_files(
            "src/quickjs-debugger.c",
            "src/quickjs-debugger-transport.c"
        )
    end

target("qjsc")
    use_packages()
    add_files("src/qjsc.c")
    add_deps("quickjs")

target("qjs")
    use_packages()
    add_files("src/qjs.c", "build/generate/repl.c", "build/generate/qjscalc.c")
    add_deps("qjsc")

target("unicode_gen")
    use_packages()
    add_files(
        "src/unicode_gen.c",
        "src/cutils.c"
    )

local quickjs_host = {
    windows= "win32",
    macosx= "darwin",
    iphoneos= "ios",
    mingw= "win32",
}

local quickjs_arch = {
    x86_64= "x64",
    ["arm64-v8a"]= "arm64",
    armeabi= "arm32",
    ["armeabi-v7a"]= "arm32"
}

target("tests/bjson")
    set_kind("shared")
    use_packages()
    add_deps("quickjs")
    add_files(
        "tests/bjson.c"
    )
    add_defines(
        "JS_SHARED_LIBRARY=1"
    )
    if is_plat("windows", "mingw") then
        add_defines("JS_EXPORT=__declspec(dllexport)")
    else
        add_cxflags("-fPIC")
        add_files("src/module.map")
    end
    after_build(function (target)
        os.mkdir("$(buildir)/lib/")
        local h = quickjs_host[os.host()] == nil and os.host() or quickjs_host[os.host()]
        local a = quickjs_arch[os.arch()] == nil and os.arch() or quickjs_arch[os.arch()]
        local pf = h.."-"..a
        os.cp(target:targetfile(), "$(buildir)/lib/"..path.basename(target:targetfile()).."."..pf..".so")
    end)
-- curl -L https://github.com/tc39/test262/tarball/36d2d2d -o tc39-test262.tgz
target("run-test262")
    use_packages()
    add_deps("quickjs")
    add_files("tests/test262/run-test262.c")

target("tsc")
    use_packages()
    add_includedirs(".")
    add_deps("quickjs")
    add_files("build/generate/tsc.c")
