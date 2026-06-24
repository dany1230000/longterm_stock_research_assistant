# 00631L lab v5.47 brief release check

v5.47 makes `scripts\00631l_release_check.cmd` easier to read.

## Changes

- Release check now prints compact output by default.
- The compact output keeps:
  - overall status
  - warnings and failures
  - next action
  - step name, status, message, and exit code
- The compact output omits each step's `stdoutTail` and `stderrTail`.
- Use `--verbose` when the full per-step output is needed for debugging.

## Commands

```cmd
scripts\00631l_release_check.cmd
scripts\00631l_release_check.cmd --verbose
```

`WARN` remains acceptable only when `failures=[]` and the warnings are known
local or off-hours data states.
