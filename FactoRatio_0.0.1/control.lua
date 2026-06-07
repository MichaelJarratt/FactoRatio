--"commands" acceses the LuaCommandProcessor
--"add_command" takes in three parameters (name -> string, help -> string, function)

--https://jackhugh.github.io/factorio-data-raw-visualiser/

function getRecipe(tableIn) --Event pass a table into the function

	--game.get_player() returns a LuaPlayer object
	local player = game.get_player(tableIn.player_index)

	local itemName, Ops = parseParameters(tableIn.parameter)

	--print a message to just the player who sent it
	player.print("Searching for item " .. itemName .." Per second: " .. Ops)

	--Recursively builds a data structure Recipe, unitsPerSecond (for one assembler) and ingredient recipes
	local recipe = getRecipeTable(itemName)
	log(serpent.block(recipe))

	--Calculate recipe ratios

	--Output Assemblers
	--Some recipes have multiple products (e.g. advanced oil processing) so products is an array
	-- local assemblers = math.ceil(Ops / recipe.unitsPerSecond)
	-- player.print(assemblers)

	recursivePrintAssemblers(recipe, Ops)
	-- player.print(serpent.block(recipe))


end

function recursivePrintAssemblers(recipeTable, OpS)
	local assemblers = math.ceil(OpS / recipeTable.unitsPerSecond)
	log(recipeTable.name .. " Assemblers: " .. assemblers)

	for i = 1, #recipeTable.ingredientsTable, 1 do
		local inputAmount = recipeTable.ingredients[i].amount
		local inputPerSecond = (inputAmount / recipeTable.craftingTime) * assemblers
		log(recipeTable.name .. " Input: " .. inputPerSecond .. " " .. recipeTable.ingredients[i].name .. " Per second")
		recursivePrintAssemblers(recipeTable.ingredientsTable[i], inputPerSecond)
	end
end

function getRecipeTable(itemName)
	log("Searching for item " .. itemName)
	local luaRecipePrototype = prototypes.recipe[itemName]
	if luaRecipePrototype ~= nil then
		local recipe = recipeToTable(luaRecipePrototype)
		return recipe
	else
		log("Found base item: " .. itemName)
	end
	-- log(serpent.block(recipe))
end

--https://lua-api.factorio.com/stable/classes/LuaRecipePrototype.html
function recipeToTable(luaRecipePrototype)

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