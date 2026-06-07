--bootstrap
package.path = package.path .. ";./FactoRatio_0.0.1/?.lua"

--- recipe_capture.lua is a dump of every recipe exported from the running game
recipe = require("recipe_capture")

---
--- Factorio mocks
--- To test in the IDE the factorio API elements need to be mocked out before loading the control module.
---
commands = {}
function commands:add_command()
    print("Command Registered")
end

factoRatio = require("control")


print(recipe["accumulator"])