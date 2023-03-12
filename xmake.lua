add_rules("mode.debug", "mode.release")

if is_plat("windows") then
    add_cxflags("/utf-8")
elseif is_plat("mingw") then
    add_ldflags("-pthread")
    add_ldflags("-static")
    add_shflags("-pthread")
    add_cxflags("-fPIC")
end

add_defines(
    "CONFIG_VERSION=\"2021-03-27\"",
    "_GNU_SOURCE=1",
    "CONFIG_BIGNUM=1",
    "CONFIG_DIRECT_DISPATCH=0"
    -- "CONFIG_DEBUGGER"
)

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
    end
    if is_plat("windows", "mingw") then
        add_syslinks("ws2_32")
    end
end

target("quickjs")
    set_kind("static")
    use_packages()
    add_files(
        "quickjs.c",
        "libregexp.c",
        "libunicode.c",
        "cutils.c",
        "quickjs-libc.c",
        "libbf.c"
        -- "quickjs-debugger.c",
        -- "quickjs-debugger-transport-win.c"
    )


target("qjsc")
    use_packages()
    add_files("qjsc.c")
    add_deps("quickjs")

target("qjs")
    use_packages()
    add_files("qjs.c", "build/repl.c", "build/qjscalc.c")
    add_deps("qjsc")
    before_build(function (target)
        os.cd(path.join(os.scriptdir()))
        os.execv(path.join(target:targetdir(), "qjsc"), {
            "-fbignum",
            "-c",
            "-o",
            "build/qjscalc.c",
            "qjscalc.js"
        })
        os.execv(path.join(target:targetdir(), "qjsc"), {
            "-c",
            "-o",
            "build/repl.c",
            "-m",
            "repl.js"
        })
        os.cd("-")
    end)

target("unicode_gen")
    use_packages()
    add_files(
        "unicode_gen.c",
        "cutils.c"
    )

target("tests/bjson")
    set_kind("shared")
    use_packages()
    add_deps("quickjs")
    add_files(
        "tests/bjson.c"
    )
    add_defines(
        "JS_SHARED_LIBRARY=1",
        "JS_EXPORT=__declspec(dllexport)"
    )
