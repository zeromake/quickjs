import("net.http")
import("utils.archive")
import("lib.detect.find_program")

local quickjsfs = [[
  function getQuickJSSystem() {
    var executable_path = scriptArgs[0];
    var args = scriptArgs.slice(1);
    var useCaseSensitiveFileNames;
    var newLine;
    var realpath = function (path) {
      var [res, err] = os.realpath(path);
      return res;
    };
    if (os.platform === "win32") {
      newLine = "\r\n";
      useCaseSensitiveFileNames = false;
    } else {
      newLine = "\n";
      useCaseSensitiveFileNames = true;
    }
    function getAccessibleFileSystemEntries(path) {
      var entries, err, st;
      [entries, err] = os.readdir(path || ".");
      if (err != 0)
        return emptyFileSystemEntries;
      entries = entries.sort();
      var files = [];
      var directories = [];
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i];
        if (entry === "." || entry === "..") {
          continue;
        }
        var name = combinePaths(path, entry);
        [st, err] = os.stat(name);
        if (err != 0)
          continue;
        if ((st.mode & os.S_IFMT) == os.S_IFREG) {
          files.push(entry);
        } else if ((st.mode & os.S_IFMT) == os.S_IFDIR) {
          directories.push(entry);
        }
      }
      return { files: files, directories: directories };
    }
    function getDirectories(path) {
      var entries, err, st;
      var [entries, err] = os.readdir(path);
      if (err != 0)
        return [];
      var directories = [];
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i];
        var name = combinePaths(path, entry);
        [st, err] = os.stat(name);
        if (err != 0)
          continue;
        if ((st.mode & os.S_IFMT) == os.S_IFDIR) {
          directories.push(entry);
        }
      }
      return directories;
    }

    return {
      newLine: newLine,
      args: args,
      useCaseSensitiveFileNames: useCaseSensitiveFileNames,
      write: function (s) {
        std.out.puts(s);
      },
      readFile: function (path, _encoding) {
        var f, ret;
        try {
          f = std.open(path, "r");
          ret = f.readAsString();
          f.close();
        } catch (e) {
          ret = undefined;
        }
        return ret;
      },
      writeFile: function (path, data, writeByteOrderMark) {
        var f;
        try {
          f = std.open(path, "w");
          f.puts(data);
          f.close();
        } catch (e) {
        }
      },
      resolvePath: function (s) { return s; },
      fileExists: function (path) {
        let [st, err] = os.stat(path);
        if (err != 0)
          return false;
        return (st.mode & os.S_IFMT) == os.S_IFREG;
      },
      deleteFile: function (path) {
        os.remove(path);
      },
      getModifiedTime: function (path) {
        let [st, err] = os.stat(path);
        if (err != 0)
          throw std.Error(err);
        return st.mtime; /* ms */
      },
      setModifiedTime: function (path, time) {
        os.utimes(path, time, time);
      },
      directoryExists: function (path) {
        let [st, err] = os.stat(path);
        if (err != 0)
          return false;
        return (st.mode & os.S_IFMT) == os.S_IFDIR;
      },
      createDirectory: function (path) {
        var ret;
        ret = os.mkdir(path);
        if (ret == -std.EEXIST)
          throw new std.Error(-ret);
      },
      getExecutingFilePath: function () {
        return executable_path;
      },
      getCurrentDirectory: function () {
        var [cwd, err] = os.getcwd();
        return cwd;
      },
      getDirectories: getDirectories,
      getEnvironmentVariable: function (name) {
        return std.getenv(name) || "";
      },
      readDirectory: function (path, extensions, excludes, includes, depth) {
        let [cwd, err] = os.getcwd();
        return matchFiles(path, extensions, excludes, includes, useCaseSensitiveFileNames, cwd, depth, getAccessibleFileSystemEntries, realpath);
      },
      exit: function (exitCode) {
        std.exit(exitCode);
      },
      realpath: realpath,
    };
  }
]]

local curlBin = find_program("curl")
local proxyUrl = nil --"socks5://127.0.0.1:10800"

local function curlDowload(url, f)
  local argv = {"-L", "--ssl-no-revoke", "-o", f}
  if proxyUrl ~= nil then
      table.insert(argv, "-x")
      table.insert(argv, proxyUrl)
  end
  table.insert(argv, url)
  os.execv("curl", argv)
end

local function dowload(url, f)
  print("download "..f.." ing")
  if curlBin ~= nil then
      curlDowload(url, f)
  else
      http.download(url, f)
  end
  print("download "..f.." done")
end

local urls = {
  {
    "ts",
    "https://registry.npmmirror.com/typescript/-/typescript-5.0.4.tgz",
    "ts-5.0.4.tgz"
  }
}

local dowloadDir = path.join(os.scriptdir(), "build", "download")
local extractDir = path.join(os.scriptdir(), "build", "extract")

function main()
  if not os.exists(dowloadDir) then
    os.mkdir(dowloadDir)
  end
  if not os.exists(extractDir) then
    os.mkdir(extractDir)
  end
  for _, item in ipairs(urls) do
    local f = path.join(dowloadDir, item[3])
    if not os.exists(f) then
      dowload(item[2], f)
    end
    local extract = path.join(extractDir, item[1])
    if not os.exists(extract) then
      archive.extract(f, extract)
    end
  end
  local tscPath = path.join(extractDir, "ts/package")
  local tscOutput = path.join(tscPath, "lib/tsc-quickjs.js")
  if not os.exists(tscOutput) then
    local tsc = io.readfile(path.join(tscPath, "lib/tsc.js"))
    tsc = tsc:gsub('"use strict";\nvar __defProp', [[
import * as os from "os";
import * as std from "std";

var __defProp]])
    tsc = tsc:gsub('  function getNodeSystem%(%)', quickjsfs..'\n  function getNodeSystem()')
    tsc = tsc:gsub('let sys2;\n  if %(isNodeLikeSystem%(%)%) %{', [[let sys2;
  if (typeof os !== "undefined") {
    sys2 = getQuickJSSystem();
  } else if (isNodeLikeSystem()) {]])
    io.writefile(tscOutput, tsc)
  end
end
