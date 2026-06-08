--"commands" acceses the LuaCommandProcessor
--"add_command" takes in three parameters (name -> string, help -> string, function)

--https://jackhugh.github.io/factorio-data-raw-visualiser/

--Constants
KEY_BASE_RESOURCE="baseResource"
KEY_ASSEMBLERS="assemblers"
KEY_TREE_DEPTH="treeDepth"
--End Constants

function getRecipe(tableIn) --Event pass a table into the function

	--game.get_player() returns a LuaPlayer object
	--local player = game.get_player(tableIn.player_index)

	local itemName, Ops = parseParameters(tableIn.parameter)

	--print a message to just the player who sent it
	--player.print("Searching for item " .. itemName .." Per second: " .. Ops)

	--Recursively builds a data structure Recipe, unitsPerSecond (for one assembler) and ingredient recipes
	local recipe = getRecipeTable(itemName)
	log(serpent.block(recipe))

	--Calculate recipe ratios

	--Output Assemblers
	--Some recipes have multiple products (e.g. advanced oil processing) so products is an array
	--local assemblers = math.ceil(Ops / recipe.unitsPerSecond)
	--player.print(assemblers)

	local assemblersTotal = {}
	recursivePrintAssemblers(recipe, Ops, assemblersTotal)
	--player.print(serpent.block(recipe))
	log(serpent.block(assemblersTotal))
end

function getRecipe2(tableIn) --Event pass a table into the function
	local itemName, Ops = parseParameters(tableIn.parameter)

	local temp = buildRecipeTree(itemName)
	calculateRatios(temp, Ops)

	log(serpent.block(temp))

	printAssemblers(temp)
end

---Takes the name of a craftable item and builds a tree of all child recipes.
---This function will also calculate the number of units produced per second by one assembler (assuming a crafting speed of 1), which is important to calculating assembler ratios later.
---@param itemName string
---@param treeDepth integer [optional] Counter of how deeply nested a recipe is in the tree
---@return table
function buildRecipeTree(--[[requred]]itemName, --[[optional]]treeDepth)
	--bootstrap
	treeDepth = treeDepth or 0
	
	--get game engine recipe object
	local luaRecipePrototype = prototypes.recipe[itemName]
	if luaRecipePrototype == nil then
		return nil
	end

	--If object was found, convert to our table format
	local recipe = recipeToTable(luaRecipePrototype)

	--Handle tree depth
	recipe[KEY_TREE_DEPTH] = treeDepth
	treeDepth = treeDepth + 1 --increment treeDepth for the next nested layer

	--Recursively build tree of recipes
	for index, ingredientRecipe in ipairs(recipe.ingredients) do
		local temp = buildRecipeTree(ingredientRecipe.name, treeDepth)
		
		if temp ~= nil then
		--Number of ingredients to craft one item of parent recipe
		temp["amount"] = ingredientRecipe.amount
			recipe.ingredients[index] = temp
		else
			recipe.ingredients[index][KEY_BASE_RESOURCE] = true
			recipe.ingredients[index][KEY_TREE_DEPTH] = treeDepth + 1
		end
	end

	return recipe;
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

	--leaf node. Does not have a recipe, so does not have any numbe of assemblers
	if recipe[KEY_BASE_RESOURCE] ~= nil then
		formatted = padding..recipe["name"].." units /s "..recipe["inputPerSecond"]
		log(formatted)
		return
	else
		-- local formatted = string.format("%s%s%s", padding, recipe[KEY_ASSEMBLERS])
		formatted = padding..recipe["name"].." Assemblers: "..recipe.assemblers
	end

	log(formatted)

	for _, ingredientRecipe in ipairs(recipe.ingredients) do
		printAssemblers(ingredientRecipe)
	end
end

--https://lua-api.factorio.com/stable/classes/LuaRecipePrototype.html
function recipeToTable(luaRecipePrototype)

	log("converting prototype to table: " .. luaRecipePrototype.name)
	--Create table from luaRecipePrototype
	local recipe = {
		name = luaRecipePrototype.name,
		craftingTime = luaRecipePrototype.energy,
		products = luaRecipePrototype.products,
		ingredients = luaRecipePrototype.ingredients,
	}

	--Calculate recipe data
	--recipe["unitsPerSecond"] = recipe.products[1]["amount"] / recipe.craftingTime
	--table.insert(recipe, "unitsPerSecond", recipe.products[1]["amount"] / recipe.craftingTime)

	return recipe
end


function recursivePrintAssemblers(recipeTable, OpS, assemblersTotal)
	--Bootstrap
	assemblersTotal = assemblersTotal or {}
	
	local assemblers = math.ceil(OpS / recipeTable.unitsPerSecond)
	log(recipeTable.name .. " Assemblers: " .. assemblers)

	assemblersTotal[recipeTable.name] = (assemblersTotal[recipeTable.name] or 0) + assemblers

	for i = 1, #recipeTable.ingredientsTable, 1 do
		local inputAmount = recipeTable.ingredients[i].amount
		local inputPerSecond = (inputAmount / recipeTable.craftingTime) * assemblers
		log(recipeTable.name .. " >Input: " .. inputPerSecond .. " " .. recipeTable.ingredients[i].name .. " Per second")
		recursivePrintAssemblers(recipeTable.ingredientsTable[i], inputPerSecond, assemblersTotal)
	end
end

function getRecipeTable2(itemName)
	log("Searching for item " .. itemName)
	local luaRecipePrototype = prototypes.recipe[itemName]
	if luaRecipePrototype ~= nil then
		local recipe = recipeToTable(luaRecipePrototype)
		return recipe
	else
		log("No Recipe for item: " .. itemName)
	end
	--log(serpent.block(recipe))
end

--https://lua-api.factorio.com/stable/classes/LuaRecipePrototype.html
function recipeToTable2(luaRecipePrototype)

	log("converting prototype to table: " .. luaRecipePrototype.name)
	--Create table from luaRecipePrototype
	local recipe = {
		name = luaRecipePrototype.name,
		craftingTime = luaRecipePrototype.energy,
		products = luaRecipePrototype.products,
		unitsPerSecond = 0,
		ingredients = luaRecipePrototype.ingredients,
		ingredientsTable = {}
	}

	--Calculate recipe data
	recipe.unitsPerSecond = recipe.products[1]["amount"] / recipe.craftingTime

	for _, ingredient in pairs(recipe.ingredients) do
		local ingredientRecipe = getRecipeTable(ingredient.name)
		table.insert(recipe.ingredientsTable, ingredientRecipe)
	end

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