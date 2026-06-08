--"commands" acceses the LuaCommandProcessor
--"add_command" takes in three parameters (name -> string, help -> string, function)

--https://jackhugh.github.io/factorio-data-raw-visualiser/

--Constants
KEY_BASE_RESOURCE="baseResource"
KEY_ASSEMBLERS="assemblers"
KEY_TREE_DEPTH="treeDepth"
--End Constants

function getRecipe(tableIn) --Event pass a table into the function
	local itemName, Ops = parseParameters(tableIn.parameter)

	local luaRecipePrototype = prototypes.recipe[itemName]
	if luaRecipePrototype == nil then
		log("No recipe found for item: "..itemName)		
	end

	local temp = recipeToTable(luaRecipePrototype)
	-- temp1[KEY_TREE_DEPTH] = 0
	buildRecipeTree(temp, 0)

	calculateRatios(temp, Ops)

	log(serpent.block(temp))

	printAssemblers(temp)
end

---Takes a recipe table and recursively builds a tree of all child recipes
---@param recipeTable table --this table is modified
---@param treeDepth integer --[optional] Counter of how deeply nested a recipe is in the tree
function buildRecipeTree(--[[requred]]recipeTable, --[[optional]]treeDepth)
	--handle tree depth
	recipeTable[KEY_TREE_DEPTH] = treeDepth
	treeDepth = treeDepth + 1 --increment treeDepth for the next nested layer

	--get Recipe information for item
	--This is a problem. Base resources are not copied and so return the same table reference, meaning every "instance" shares the same table depth and quantities
	--This is only a problem for IDE testing, seem that in-game this returns a unique table each time
	local itemRecipe = prototypes.recipe[recipeTable.name]
	
	--leaf node
	if itemRecipe == nil then
		recipeTable[KEY_BASE_RESOURCE] = true
		recipeTable[KEY_TREE_DEPTH] = treeDepth
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

--https://lua-api.factorio.com/stable/classes/LuaRecipePrototype.html
---Convert a LuaRecipePrototype into a table
---@param luaRecipePrototype luaRecipePrototype
---@return table
function recipeToTable(luaRecipePrototype)

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