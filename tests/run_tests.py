"""Runs the headless tests for Nothing Wasted under Lua 5.1 (via lupa).

Usage: python tests/run_tests.py
Exits non-zero if any test fails.
"""
import os
import sys

import lupa.lua51 as lupa

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().print = lambda *args: print(*args)
    lua.execute(f'package.path = [[{ROOT}/tests/?.lua;]] .. package.path')
    run = lua.eval('function(root) return dofile(root .. "/tests/smoke.lua")(root) end')
    passed, failed = run(ROOT)
    print(f"\n{passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
