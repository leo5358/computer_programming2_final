#!/usr/bin/env python
import os
import sys

env = Environment()

# 設定標頭檔搜尋路徑
env.Append(CPPPATH=["src", "godot-cpp/include", "godot-cpp/gen/include", "godot-cpp/gdextension"])
env.Append(LIBPATH=["godot-cpp/bin"])

if sys.platform == "darwin":
    # 這裡必須與你 ls 看到的名稱完全一致（去掉 lib 和 .a）
    lib_name = "godot-cpp.macos.template_debug.universal"
        
    env.Append(LIBS=[lib_name])
    env.Append(CPPFLAGS=["-std=c++17", "-fPIC"])
    env.Append(LINKFLAGS=["-framework", "Cocoa"])

# 獲取原始碼
sources = Glob("src/*.cpp")

# 編譯目標
# 注意：輸出的檔名建議與你的 .gdextension 檔案中定義的一致
library = env.SharedLibrary(
    "project/bin/libgdexample", 
    source=sources,
)

Default(library)
