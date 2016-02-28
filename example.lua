#!/usr/bin/env carbon
local handler = require("init")
print(handler)
srv.DefaultRoute(handler)
