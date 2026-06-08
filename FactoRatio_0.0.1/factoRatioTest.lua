--bootstrap
package.path = package.path .. ";./FactoRatio_0.0.1/?.lua"

-- recipe_capture.lua is a dump of every recipe exported from the running game
recipe_capture = require("recipe_capture")

-- Serpent is a table serialization library used by factorio
serpent = require("lib.serpent")

---
--- Factorio mocks
--- To test in the IDE the factorio API elements need to be mocked out before loading the control module.
---
commands = {}
function commands:add_command()
    print("Command Registered")
end

-- mock logging
function log(string)
    print("Logged: "..string)
end

-- mock prototypes
prototypes = {
    recipe=recipe_capture
}

-- Now that dependencies have been mocked, load control module.
factoRatio = require("control")

-- local accumulator = prototypes.recipe["accumulator"]
-- print(serpent.block(accumulator, {metatostring=false}))

-- No namespacing, the function is now just available to be called.
getRecipe({parameter="accumulator"})