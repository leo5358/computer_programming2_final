#!/usr/bin/env python
import os

# 1. Get the base environment from godot-cpp
# This handles all platform-specific flags, compilers, and suffixes.
env = SConscript("godot-cpp/SConstruct")

# 2. Add our own include paths
env.Append(CPPPATH=["src"])

# 3. Collect all C and C++ source files
sources = Glob("src/*.cpp") + Glob("src/*.c")

# 4. Define the output library path and name
# Using env["suffix"] ensures names like: libgdexample.linux.template_debug.x86_64.so
# Using env["SHLIBSUFFIX"] handles .so, .dylib, or .dll automatically.
target_path = os.path.join("project", "bin", "libgdexample{}{}".format(env["suffix"], env["SHLIBSUFFIX"]))

library = env.SharedLibrary(
    target=target_path,
    source=sources,
)

# 5. Disable caching for the library to ensure clean rebuilds during development
env.NoCache(library)

Default(library)
