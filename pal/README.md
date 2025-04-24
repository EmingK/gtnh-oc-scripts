# Platform Abstraction Layer

This module implements OpenComputers API on PC platforms, making development
and unit tests available on PC.

To use these implementations, you must use `palRequire` to import original
OC modules.

``` lua
require 'core.pal'

local computer = palRequire('computer')
```

## Requirements

Third party lua libraries are used to implement functions not supported by
lua builtin abilities. We prefer installing them via LuaRocks.

## Functionality

We only implement APIs used inside this project. PRs implementing other APIs
are also welcomed.
