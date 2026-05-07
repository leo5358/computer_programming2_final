#!/usr/bin/env python

env = SConscript("godot-cpp/SConstruct")

env.Append(CPPPATH=["src"])

sources = Glob("src/*.cpp") + Glob("src/*.c")

library = env.SharedLibrary(
    "project/bin/libgdexample{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
    source=sources,
)

env.NoCache(library)
Default(library)
