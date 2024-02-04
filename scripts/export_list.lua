local list = {
    "JS_NewRuntime",
    "JS_NewRuntime2",
    "JS_FreeRuntime",
    "JS_GetRuntime",
    "JS_SetRuntimeInfo",
    "JS_UpdateStackTop",
    "JS_SetGCThreshold",
    "JS_NewContext",
    "JS_FreeContext",
    "JS_GetContextOpaque",
    "JS_SetContextOpaque",
    "JS_AddIntrinsicBigFloat",
    "JS_AddIntrinsicBigDecimal",
    "JS_AddIntrinsicOperators",
    "JS_EnableBignumExt",
    "JS_ThrowReferenceError",
    "__JS_FreeValue",
    "JS_DetectModule",
    "JS_Eval",
    "JS_SetModuleLoaderFunc",
    "JS_NewCModule",
    "JS_SetMaxStackSize",
    "JS_ComputeMemoryUsage",
    "JS_DumpMemoryUsage",
    "JS_SetHostPromiseRejectionTracker",
    "JS_EvalFunction",
    "JS_SetMemoryLimit",
    "JS_AddModuleExport",
    "JS_SetModuleExport",
    "JS_AddModuleExportList",
    "JS_SetModuleExportList",
    "JS_ResolveModule",
    "JS_GetScriptOrModuleName",
    "JS_NewCFunction2",
    "JS_NewCFunctionData",
    "JS_SetConstructor",
    "JS_SetPropertyFunctionList",
    "JS_Call",
    "JS_SetCanBlock",
    "JS_SetIsHTMLDDA",
    "JS_ExecutePendingJob",
    "JS_NewCFunction2",

    "JS_ToBool",

    "JS_ToInt32",
    "JS_ToInt64",
    "JS_ToIndex",
    "JS_ToFloat64",
    "JS_ToBigInt64",

    "JS_NewStringLen",
    "JS_NewString",
    "JS_NewAtomString",
    "JS_ToString",

    "JS_AtomToCString",
    "JS_ToCStringLen2",
    "JS_FreeCString",

    "JS_NewObjectProtoClass",
    "JS_NewObjectClass",
    "JS_NewObjectProto",
    "JS_NewObject",

    "JS_IsFunction",
    "JS_IsConstructor",

    "JS_NewArray",
    "JS_IsArray",

    "JS_GetPropertyStr",
    "JS_GetPropertyUint32",
    "JS_SetPropertyUint32",
    "JS_SetPropertyInt64",
    "JS_SetPropertyStr",
    "JS_HasProperty",
    "JS_DeleteProperty",
    "JS_SetPrototype",
    "JS_GetPrototype",
    "JS_ToPropertyKey",
    "JS_WriteObject",
    "JS_WriteObject2",
    "JS_ReadObject",
    "JS_GetOwnPropertyNames",
    "JS_GetOwnProperty",

    "JS_GetGlobalObject",
    "JS_IsInstanceOf",
    "JS_DefineProperty",
    "JS_DefinePropertyValue",
    "JS_DefinePropertyValueStr",
    "JS_DefinePropertyGetSet",

    "JS_SetOpaque",
    "JS_GetOpaque",

    "JS_ParseJSON",
    "JS_ParseJSON2",
    "JS_JSONStringify",

    "JS_IsExtensible",
    "JS_PreventExtensions",

    "JS_GetArrayBuffer",
    "JS_NewArrayBuffer",
    "JS_NewArrayBufferCopy",
    "JS_DetachArrayBuffer",
    "JS_GetTypedArrayBuffer",

    "JS_NewPromiseCapability",
    "JS_SetHostPromiseRejectionTracker",
    "JS_SetInterruptHandler",

    "JS_IsError",
    "JS_ThrowRangeError",
    "JS_ThrowTypeError",
    "JS_ThrowOutOfMemory",
    "JS_GetException",

    "js_malloc",
    "js_free",
    "js_realloc",
    "js_std_dump_error",
    "js_load_file",
    "js_init_module_std",
    "js_init_module_os",
    "js_std_add_helpers",
    "js_std_loop",
    "js_std_init_handlers",
    "js_std_free_handlers",
    "js_module_set_import_meta",
    "js_module_loader",
    "js_std_eval_binary",
    "js_std_promise_rejection_tracker",
    "js_std_set_worker_new_context_func",
    "js_string_codePointRange",
    "js_std_await",
    "strstart",
    "has_suffix",
    "pstrcpy",
}


local extractMap = path.join(os.scriptdir(), "..", "build", "generate/quickjs.map")
local extractDef = path.join(os.scriptdir(), "..", "build", "generate/quickjs.def")
local extractExp = path.join(os.scriptdir(), "..", "build", "generate/quickjs.exp")

local extractMapFile = io.open(extractMap, "wb")
local extractDefFile = io.open(extractDef, "wb")
local extractExpFile = io.open(extractExp, "wb")

extractMapFile:write([[{
global:
]])
extractDefFile:write([[
LIBRARY
    EXPORTS
]])
for _, fn in ipairs(list) do
    extractMapFile:write(string.format('    %s;\n', fn))
    extractDefFile:write(string.format('        %s\n', fn))
    extractExpFile:write(string.format('_%s\n', fn))
end
extractMapFile:write([[local:
    *;
};]])
extractMapFile:close()
extractDefFile:close()
extractExpFile:close()
