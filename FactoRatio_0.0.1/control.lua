--"commands" acceses the LuaCommandProcessor
--"add_command" takes in three parameters (name -> string, help -> string, function)

--https://jackhugh.github.io/factorio-data-raw-visualiser/

--custom meta tables
require("metatables")

--Constants
KEY_BASE_RESOURCE="baseResource"
KEY_ASSEMBLERS="assemblers"
KEY_TREE_DEPTH="treeDepth"

--Dependency Tree Symbol Constants
S_EMPTY="   "
S_CHILD="+- "
S_LEAF="\\- "
S_CONT ="|  "
--End Constants

function getRecipe(tableIn) --Event pass a table into the function
	local itemName, Ops = parseParameters(tableIn.parameter)

	local luaRecipePrototype = prototypes.recipe[itemName]
	if luaRecipePrototype == nil then
		log("No recipe found for item: "..itemName)		
	end

	local temp = recipeToTable(luaRecipePrototype)
	addRecipeMetaTable(temp)
	-- temp1[KEY_TREE_DEPTH] = 0
	buildRecipeTree(temp, 1)

	calculateRatios(temp, Ops)

	-- log(serpent.block(temp))

	-- printAssemblers(temp)

	-- log(formatAssemblers(temp))

	local dependencyTree = formatDepTree({recipe = temp})

	for index, value in ipairs(dependencyTree) do
    	log(value)
	end
end

---Takes a recipe table and recursively builds a tree of all child recipes
---@param recipeTable table --this table is modified
---@param treeDepth integer --[optional] Counter of how deeply nested a recipe is in the tree
function buildRecipeTree(--[[requred]]recipeTable, --[[optional]]treeDepth)
	--handle tree depth
	recipeTable[KEY_TREE_DEPTH] = treeDepth
	treeDepth = treeDepth + 1 --increment treeDepth for the next nested layer
	addRecipeMetaTable(recipeTable)

	--get Recipe information for item
	--This is a problem. Base resources are not copied and so return the same table reference, meaning every "instance" shares the same table depth and quantities
	--This is only a problem for IDE testing, seem that in-game this returns a unique table each time
	local itemRecipe = prototypes.recipe[recipeTable.name]
	
	--leaf node
	if itemRecipe == nil then
		recipeTable[KEY_BASE_RESOURCE] = true
		recipeTable[KEY_TREE_DEPTH] = treeDepth -1
		return
	end
	--copy recipe information into table
	recipeTable["craftingTime"] = itemRecipe["energy"]
	recipeTable["products"] = itemRecipe["products"]
	recipeTable["ingredients"] = itemRecipe["ingredients"]

	--Recursively build tree of recipes
	for index, ingredientRecipe in ipairs(recipeTable.ingredients) do
		buildRecipeTree(ingredientRecipe, treeDepth)
	end
end

function calculateRatios(recipe, outputPerSecond)
	--base case. This index is used to flag that an ingredient has no crafting recipe. (Typically ores)
	if recipe[KEY_BASE_RESOURCE] ~= nil then
		return
	end

	--Units/s per assembler (assuming crafting speed of 1)
	recipe["unitsPerSecond"] = recipe.products[1]["amount"] / recipe.craftingTime
	--Assemblers required to meet output per second
	recipe[KEY_ASSEMBLERS] = math.ceil(outputPerSecond / recipe.unitsPerSecond)

	for _, ingredientRecipe in ipairs(recipe.ingredients) do
		--How many inputs of the ingredient are required per second per parent recipe assembler
		ingredientRecipe["inputPerSecond"] = ingredientRecipe.amount / recipe.craftingTime
		--How many total inputs are required for the parent set of assemblers
		ingredientRecipe["totalInputPerSecond"] = ingredientRecipe["inputPerSecond"] * recipe[KEY_ASSEMBLERS]
		calculateRatios(ingredientRecipe, ingredientRecipe["totalInputPerSecond"])
	end

end

function printAssemblers(recipe)
	local padding = string.rep("  ", recipe[KEY_TREE_DEPTH])
	local formatted

	--leaf node. Does not have a recipe, so does not have any number of assemblers
	if recipe[KEY_BASE_RESOURCE] ~= nil then
		formatted = padding..recipe["name"].." units /s "..recipe["totalInputPerSecond"].." ("..recipe["inputPerSecond"].." per producer)"
		log(formatted)
		return
	elseif recipe["totalInputPerSecond"] ~= nil then --Branch Node
		-- local formatted = string.format("%s%s%s", padding, recipe[KEY_ASSEMBLERS])
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers.." (Producing "..recipe["totalInputPerSecond"].." per second, or "..recipe["inputPerSecond"].." per assembler)"
	else
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers
	end

	log(formatted)

	for _, ingredientRecipe in ipairs(recipe.ingredients) do
		printAssemblers(ingredientRecipe)
	end
end

-- TODO: pass a table (be reference) and use it as a map to count the total number of each resource / assembler
function formatAssemblers(--[[requred]]recipe)
	local formatted
	log(recipe:format())
	local padding = string.rep(" ", recipe[KEY_TREE_DEPTH])

	--Process this recipe
	--Root node. The root node does not input into anything, so does not have a "totanInputPerSecond"
	if recipe["totalInputPerSecond"] == nil then
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers.."\n"
	--Branch node. Inputs into parent recipe and has its own input recipes.
	elseif recipe[KEY_BASE_RESOURCE] == nil then
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers.." (Producing "..recipe["totalInputPerSecond"].." per second, or "..recipe["inputPerSecond"].." per assembler)".."\n"
	--Leaf node. Does not have a recipe, so does not have any number of assemblers
	else
		formatted = padding..recipe["name"].." units /s "..recipe["totalInputPerSecond"].." ("..recipe["inputPerSecond"].." per producer)".."\n"
	end

	---Process children
	---table.index being nil is falsy, inversely table.index having a value is truthy.
	---If not a leaf node, recursively call upon input recipes
	if recipe.ingredients then
		for _, ingredientRecipe in pairs(recipe.ingredients) do
			formatted = formatted..formatAssemblers(ingredientRecipe)
		end
	end

	return formatted
end


function formatAssemblersOG(--[[requred]]recipe, --[[optional]]outString)
	--bootstrap
	outString = outString or ""
	log(getmetatable(recipe).__formatRecipeString())
	local padding = string.rep("  ", recipe[KEY_TREE_DEPTH])

	local formatted

	--leaf node. Does not have a recipe, so does not have any number of assemblers
	if recipe[KEY_BASE_RESOURCE] ~= nil then
		formatted = padding..recipe["name"].." units /s "..recipe["totalInputPerSecond"].." ("..recipe["inputPerSecond"].." per producer)".."\n"
	elseif recipe["totalInputPerSecond"] ~= nil then --Branch Node
		-- local formatted = string.format("%s%s%s", padding, recipe[KEY_ASSEMBLERS])
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers.." (Producing "..recipe["totalInputPerSecond"].." per second, or "..recipe["inputPerSecond"].." per assembler)".."\n"
	else
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers.."\n"
	end

	outString = outString..formatted

	local children = ""
	for _, ingredientRecipe in pairs(recipe.ingredients or {}) do
		children=children..formatAssemblers(ingredientRecipe)
	end
	outString = outString..children

	return outString
end

---Takes a recipe tree and returns a table of strings which amount to a pretty-printed representation of the input tree.
---
---<b>Implementation notes:</b>
---
---The formatted output is treated like a grid, where the symbols and recipe strings occupy rows and columns, 
---though only the columns positions are counted.
---
---A node will build up the horizontal list of symbols leading up to its string, then compile the whole line into a string. <br>
---It will then, before resursively calling upon its children, set the symbol in it's column (treeDepth) on the row beneath it.
---@param args any {recipe=inputRecipe}
---@return table formattedTable Table of formatted output. The table is in the correct print order and can be iterated over and printed.
function formatDepTree(args)
    --bootstrap / extract args
    args.tableOut = args.tableOut or {}
    --Represents what symbol to place in each depth column
    args.depthSymbols = args.depthSymbols or {}
    local thisNodeRecipe = args.recipe
    local thisNodeDepth = thisNodeRecipe.treeDepth

    --Create a list of symbols which will later be rendered into a string
    local lineSymbols = {}
    ---Iterate up to the depth of this node
    for depth=1, thisNodeDepth-1, 1 do
        local depthSymbol = args.depthSymbols[depth]

        --Symbol assigned to this node is respected
        if depth == thisNodeDepth-1 then
            lineSymbols[depth] = depthSymbol
        else--Calculate what symbol should be at this depth on this line
            if depthSymbol == S_CHILD then--If the parent recipe is a middle child, then there must be a continuation line beneath it
                lineSymbols[depth] = S_CONT
            elseif depthSymbol == S_LEAF then--If the parent recipe is a leaf child, then there must be empty space beneath it
                lineSymbols[depth] = S_EMPTY
            end
        end
    end

    --Render the line into a string
    local lineStr = ""
    for _, symbol in ipairs(lineSymbols) do
        lineStr = lineStr..symbol
    end
    lineStr = lineStr..thisNodeRecipe:format()

    ---Put rendered line into the output table.
    ---As the tree is traversed depth-first the order of insertion will be the correct rendering order
    table.insert(args.tableOut, lineStr)
    
    ---Iterate over inputs recipes
    ---Set the appropraite symbol for the child before doing a recursive call on it
    for index, inputRecipe in ipairs(thisNodeRecipe.ingredients or {}) do
        local isLastChild = index == #thisNodeRecipe.ingredients
        if isLastChild then
            args.depthSymbols[thisNodeDepth]="\\- "
        else --middle child
            args.depthSymbols[thisNodeDepth]="+- "
        end

        formatDepTree({recipe=inputRecipe, tableOut=args.tableOut, depthSymbols = args.depthSymbols})
    end

    return args.tableOut
end

-- if recipe.ing then
-- 	for _, ingredientRecipe in ipairs(recipe.ingredients) do
-- 			outString = outString..formatAssemblers(ingredientRecipe, outString)
-- 		end
-- 	end

--https://lua-api.factorio.com/stable/classes/LuaRecipePrototype.html
---Convert a LuaRecipePrototype into a table
---@param luaRecipePrototype luaRecipePrototype
---@return table
function recipeToTable(luaRecipePrototype)

	if luaRecipePrototype == nil then
		return nil
	end

	log("converting prototype to table: " .. luaRecipePrototype.name)
	--Create table from luaRecipePrototype
	local recipe = {
		name = luaRecipePrototype.name,
		craftingTime = luaRecipePrototype.energy,
		products = luaRecipePrototype.products,
		ingredients = luaRecipePrototype.ingredients,
	}

	return recipe
end

---Splits a parameter string into the item and output per second
---@param parameters string
---@return string item
---@return number OpS
function parseParameters(parameters)
	--Split parameters into array by whitespace
	local t = {}
    for str in string.gmatch(parameters, "%S+") do
        table.insert(t, str)
    end
	--Default OpS to 1 if it is not set
	if #t == 1 then
		t[2] = 1
	end
	return t[1], t[2]
end

commands.add_command("get-recipe", "A placefolder for building up to bigger things", getRecipe)

---Scrape every recipe from the loaded game instance and dump into a table that can be loaded for IDE testing.
function dumpRecipesSnapshot()
	local exported = {}
	for name, recipe in pairs(prototypes.recipe) do
		exported[name] = {
			name = recipe.name,
			ingredients = recipe.ingredients,
			products = recipe.products,
			energy = recipe.energy
		}
	end

	local fileContent = "return " .. serpent.block(exported, {comment = false})

	helpers.write_file("recipe_capture.lua", fileContent, false)
end
commands.add_command("dumpRecipes", "A placefolder for building up to bigger things", dumpRecipesSnapshot)

--[[
LuaGameScript Documentation:
	https://lua-api.factorio.com/latest/LuaGameScript.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaGameScript.html

LuaCommandProcessor Documentation:
	https://lua-api.factorio.com/latest/LuaCommandProcessor.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaCommandProcessor.html

LuaPlayer Documentation:
	https://lua-api.factorio.com/latest/LuaPlayer.html
	or
	..\Steam\steamapps\common\Factorio\doc-html\LuaPlayer.html
]]