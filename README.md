lua-consistent-hash
===================

A reimplementation of consistent hash in lua based on jaderhs' fork of consistent hash (https://github.com/jaderhs/lua-consistent-hash)

Add chash generator

chash_gen.lua Usage
-----

```lua
local chash_gen = require "chash_gen"

local chash = chash_gen.create_hash())
chash:add_upstream("192.168.0.251")
chash:add_upstream("192.168.0.252")
chash:add_upstream("192.168.0.253")

local upstream = chash:get_upstream("my_hash_key")
```

chash.lua Usage
-----

```lua
local chash = require "chash"

chash.add_upstream("192.168.0.251")
chash.add_upstream("192.168.0.252")
chash.add_upstream("192.168.0.253")

local upstream = chash.get_upstream("my_hash_key")
```
