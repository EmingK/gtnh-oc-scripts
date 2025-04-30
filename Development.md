# Development

The [platform abstraction layer](./pal/) enables running and debugging
lua programs on the PC platform. This simplifies debugging process, since
this project renders graphical user interface on the scrren, debugging 
with logs may only be seen with `--debug` option.

To prepare running on PC, you need `luarocks` installed on your computer.
Following modules should be installed with `luarocks`:

- `luasystem`, provides precise timing support, used to implement `computer.uptime`.
- `lcurses`, used to implement `gpu` and `term`. You may need to patch
  this project if you use lua 5.4.
- `lpath`, used to implement `filesystem`.

Once dependent modules are installed, you can run and debug via entry
script `pcrun.lua`.

```sh
lua pcrun.lua <entry_file> <args...>
```