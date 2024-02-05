toolchain("zig")
    on_check(function (toolchain)
        if toolchain:is_plat("macosx", "iphoneos", "watchos", "appletvos", "applexros") then
            local xcode_sysroot = nil
            local cross = nil
            if toolchain:is_plat("macosx") then
                cross = "xcrun -sdk macosx "
            elseif toolchain:is_plat("iphoneos") then
                cross = simulator and "xcrun -sdk iphonesimulator " or "xcrun -sdk iphoneos "
            elseif toolchain:is_plat("watchos") then
                cross = simulator and "xcrun -sdk watchsimulator " or "xcrun -sdk watchos "
            elseif toolchain:is_plat("appletvos") then
                cross = simulator and "xcrun -sdk appletvsimulator " or "xcrun -sdk appletvos "
            elseif toolchain:is_plat("applexros") then
                cross = simulator and "xcrun -sdk xrsimulator " or "xcrun -sdk xros "
            else
                raise("unknown platform for xcode!")
            end
            local sdkpath = try { function () return os.iorun(cross .. "--show-sdk-path") end }
            if sdkpath then
                xcode_sysroot = sdkpath:trim()
            else 
                raise("unknown osx sysroot!")
            end
            toolchain:config_set("xcode_sysroot", xcode_sysroot)
        end
    end)
    on_load(function (toolchain)
        if toolchain:is_plat("macosx", "iphoneos", "watchos", "appletvos", "applexros") then
            local xcode_sysroot = toolchain:config("xcode_sysroot")
            local xcode_framework = path.join(xcode_sysroot, "/System/Library/Frameworks")
            local xcode_include = path.join(xcode_sysroot, "/usr/include")
            toolchain:add("zig_cc.cxflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework, "-I"..xcode_include)
            toolchain:add("zig_cc.ldflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework, "-I"..xcode_include)
            toolchain:add("zig_cc.shflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework, "-I"..xcode_include)
            toolchain:add("zig_cxx.cxflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework, "-I"..xcode_include)
            toolchain:add("zig_cxx.ldflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework)
            toolchain:add("zig_cxx.shflags", "-isysroot", xcode_sysroot, "-F"..xcode_framework)
            toolchain:add("zcflags", "-sdk " .. xcode_sysroot)
            toolchain:add("zcldflags", "-sdk " .. xcode_sysroot)
            toolchain:add("zcshflags", "-sdk " .. xcode_sysroot)
        end
    end)