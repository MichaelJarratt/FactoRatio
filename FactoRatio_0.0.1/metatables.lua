function addRecipeMetaTable(recipe)
      local recipeFunctions = {}
    function recipeFunctions:format()
        --Process this recipe
        --Root node. The root node does not input into anything, so does not have a "totalInputPerSecond"
        if recipe["totalInputPerSecond"] == nil then
            return recipe["name"].." Assemblers: "..recipe.assemblers
        --Branch node. Inputs into parent recipe and has its own input recipes.
        elseif recipe[KEY_BASE_RESOURCE] == nil then
            return recipe["name"].." Assemblers: "..recipe.assemblers.." (Producing "..recipe["totalInputPerSecond"].." per second, or "..recipe["inputPerSecond"].." per assembler)"
        --Leaf node. Does not have a recipe, so does not have any number of assemblers
        else
            return recipe["name"].." units /s "..recipe["totalInputPerSecond"].." ("..recipe["inputPerSecond"].." per producer)"
        end
    end
    setmetatable(recipe,{__index = recipeFunctions})
end