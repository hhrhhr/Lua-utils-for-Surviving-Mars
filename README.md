# Lua utils for Surviving Mars

# requirements

* [Lua 5.3](https://www.lua.org)
* [lua-lz4](https://github.com/witchu/lua-lz4)

## hpk unpack

* inspect: ````lua hpk_unpack.lua <input.hpk>````
* unpack: ````lua hpk_unpack.lua <input.hpk> <output_dir>````

## example

````
> lua hpk_unpack.lua Shaders.hpk
36      382     ProjectShaders\Const.fh
418     1464    Shaders\Base.fh
1882    568     Shaders\Billboard.fx
2450    516     Shaders\BlendSwitch.fh
2966    1129    Shaders\Blit.fx
4095    1514    Shaders\BreakingWaves.fh
5609    1141    Shaders\Clear.fx
6750    5548    Shaders\Common.fh
12298   2089    Shaders\Construction.fx
...
>_
````
