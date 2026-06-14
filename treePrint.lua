S_EMPTY="   "
S_CHILD="+- "
S_LEAF="\\- "
S_CONT ="|  "

local nestedTable = {
    name = "accumulator Assemblers: 10",
    treeDepth = 0,
    recipe = {
        {
            name = "Iron Plate Assemblers: 7",
            treeDepth = 1,
            recipe = {
                {
                    text = "Iron Ore units /s 2.1875",
                    treeDepth = 2,
                }
            }
        }
    }
}

print(_VERSION)

---Each element of the tree is responsible for it's own marker. Child / final child.
---Elements are responsible for the continuity lines of their child elements, and manipulate the returned strings from their children to add them.
---@param recipe any
---@param isLastChild any
function printDepTree(recipe, isLastChild)
    local padding = ""
    local marker = ""
    -- if recipe.treeDepth==1 then
    --     modifier=modifier.."+-"
    -- elseif recipe.treeDepth>1 then
    --     modifier="+-"
    -- end
    --The root node does not receive any padding or formatting
    if recipe["treeDepth"] ~=0 then
        padding = string.rep("   ", recipe["treeDepth"]-1)
        if isLastChild then
            marker="\\- "
        else --middle child
            marker="+- "
        end
    end


    print(padding..marker..recipe.name)
    -- print("Is last child: ", (isLastChild or false))

    for index, inputRecipe in ipairs(recipe.ingredients or {}) do
        local isLastChild = index == #recipe.ingredients
        printDepTree(inputRecipe, isLastChild)
    end
end

local function replaceAt( str, at, with ) return string.sub(str, 1, at-1 )..with..(string.sub(str, at+1, string.len(str))) end

---
---@param str any
---@param at any first character of the three-character symbol
---@param with any new symbol
function replaceTreeSymbol(str, at, with)
    local temp = string.sub(str, 1, at-1)
    local temp2 = string.sub(str, at+3, #str)
    return temp..with..temp2
end

--This attempt used direct string manipulation, but it got messy when it came to replacing symbols
function formatDepTree_old(args)
    --bootstrap / extract args
    args.tableOut = args.tableOut or {}
    --Represents what symbol to place in each depth column
    args.depthSymbols = args.depthSymbols or {}
    local currentRecipe = args.recipe

    --Each graph symbol is 3 characters wide.
    --Make line the correct length and then substitue in symbols
    local line = string.rep("  ", currentRecipe.treeDepth-1)

    --Build preceeding depth symbols before recipe string
    for depth, value in ipairs(args.depthSymbols) do
        local replaceIndex = currentRecipe.treeDepth-1
        line = replaceTreeSymbol(line, replaceIndex, value)
    end

    line = line..args.recipe.name


    table.insert(args.tableOut, line)
    
    for index, inputRecipe in ipairs(args.recipe.ingredients or {}) do
        local isLastChild = index == #args.recipe.ingredients
        if isLastChild then
            args.depthSymbols[args.recipe["treeDepth"]]="\\- "
        else --middle child
            args.depthSymbols[args.recipe["treeDepth"]]="+- "
        end

        formatDepTree({recipe=inputRecipe, tableOut=args.tableOut, depthSymbols = args.depthSymbols})
    end

    return args.tableOut
end

--This attempt is as above, but it is building a list of symbols, which will later be rendered into strings.
--THIS ONE WORKS
function formatDepTree(args)
    --bootstrap / extract args
    args.tableOut = args.tableOut or {}
    --Represents what symbol to place in each depth column
    args.depthSymbols = args.depthSymbols or {}
    local currentRecipe = args.recipe
    local currentDepth = currentRecipe.treeDepth

    --Create a list of symbols which will later be rendered into a string
    local line = {}
    for depth=1, currentRecipe.treeDepth-1, 1 do
        local depthSymbol = args.depthSymbols[depth]
        --Symbol assigned to the depth of this node is respected
        if depth == currentDepth-1 then
            line[depth] = depthSymbol
        --Calculate what symbol should be at this depth (deducing from the previous assignment)
        else
            --If the parent recipe is a middle child, then there must be a continuation line beneath it
            if depthSymbol == S_CHILD then
                line[depth] = S_CONT
            --If the parent recipe is a leaf child, then there must be empty space beneath it
            elseif depthSymbol == S_LEAF then
                line[depth] = S_EMPTY
            end
        end
    end

    --Render the line into a string
    local lineStr = ""
    for _, symbol in ipairs(line) do
        lineStr = lineStr..symbol
    end
    lineStr = lineStr..currentRecipe.name


    table.insert(args.tableOut, lineStr)
    
    for index, inputRecipe in ipairs(args.recipe.ingredients or {}) do
        local isLastChild = index == #args.recipe.ingredients
        if isLastChild then
            args.depthSymbols[args.recipe["treeDepth"]]="\\- "
        else --middle child
            args.depthSymbols[args.recipe["treeDepth"]]="+- "
        end

        formatDepTree({recipe=inputRecipe, tableOut=args.tableOut, depthSymbols = args.depthSymbols})
    end

    return args.tableOut
end

-- printDepTree(nestedTable)


local t = {
  assemblers = 10,
  craftingTime = 10,
  ingredients = {
    {
      amount = 2,
      assemblers = 7,
      craftingTime = 3.2000000000000002,
      ingredients = {
        {
          amount = 1,
          baseResource = true,
          inputPerSecond = 0.3125,
          name = "iron-ore",
          totalInputPerSecond = 2.1875,
          treeDepth = 3,
          type = "item"
        }
      },
      inputPerSecond = 0.2,
      name = "iron-plate",
      products = {
        {
          amount = 1,
          name = "iron-plate",
          probability = 1,
          type = "item"
        }
      },
      totalInputPerSecond = 2,
      treeDepth = 2,
      type = "item",
      unitsPerSecond = 0.3125
    },
    {
      amount = 5,
      assemblers = 20,
      craftingTime = 4,
      ingredients = {
        {
          amount = 1,
          assemblers = 16,
          craftingTime = 3.2000000000000002,
          ingredients = {
            {
              amount = 1,
              baseResource = true,
              inputPerSecond = 0.3125,
              name = "iron-ore",
              totalInputPerSecond = 5,
              treeDepth = 4,
              type = "item"
            }
          },
          inputPerSecond = 0.25,
          name = "iron-plate",
          products = {
            {
              amount = 1,
              name = "iron-plate",
              probability = 1,
              type = "item"
            }
          },
          totalInputPerSecond = 5,
          treeDepth = 3,
          type = "item",
          unitsPerSecond = 0.3125
        },
        {
          amount = 1,
          assemblers = 16,
          craftingTime = 3.2000000000000002,
          ingredients = {
            {
              amount = 1,
              baseResource = true,
              inputPerSecond = 0.3125,
              name = "copper-ore",
              totalInputPerSecond = 5,
              treeDepth = 4,
              type = "item"
            }
          },
          inputPerSecond = 0.25,
          name = "copper-plate",
          products = {
            {
              amount = 1,
              name = "copper-plate",
              probability = 1,
              type = "item"
            }
          },
          totalInputPerSecond = 5,
          treeDepth = 3,
          type = "item",
          unitsPerSecond = 0.3125
        },
        {
          amount = 20,
          assemblers = 2,
          craftingTime = 1,
          ingredients = {
            {
              amount = 1,
              assemblers = 7,
              craftingTime = 3.2000000000000002,
              ingredients = {
                {
                  amount = 1,
                  baseResource = true,
                  inputPerSecond = 0.3125,
                  name = "iron-ore",
                  totalInputPerSecond = 2.1875,
                  treeDepth = 5,
                  type = "item"
                }
              },
              inputPerSecond = 1,
              name = "iron-plate",
              products = {
                {
                  amount = 1,
                  name = "iron-plate",
                  probability = 1,
                  type = "item"
                }
              },
              totalInputPerSecond = 2,
              treeDepth = 4,
              type = "item",
              unitsPerSecond = 0.3125
            },
            {
              amount = 5,
              assemblers = 5,
              craftingTime = 1,
              ingredients = {
                {
                  amount = 30,
                  baseResource = true,
                  inputPerSecond = 30,
                  name = "water",
                  totalInputPerSecond = 150,
                  treeDepth = 5,
                  type = "fluid"
                },
                {
                  amount = 30,
                  baseResource = true,
                  inputPerSecond = 30,
                  name = "petroleum-gas",
                  totalInputPerSecond = 150,
                  treeDepth = 5,
                  type = "fluid"
                }
              },
              inputPerSecond = 5,
              name = "sulfur",
              products = {
                {
                  amount = 2,
                  name = "sulfur",
                  probability = 1,
                  type = "item"
                }
              },
              totalInputPerSecond = 10,
              treeDepth = 4,
              type = "item",
              unitsPerSecond = 2
            },
            {
              amount = 100,
              baseResource = true,
              inputPerSecond = 100,
              name = "water",
              totalInputPerSecond = 200,
              treeDepth = 4,
              type = "fluid"
            }
          },
          inputPerSecond = 5,
          name = "sulfuric-acid",
          products = {
            {
              amount = 50,
              name = "sulfuric-acid",
              probability = 1,
              type = "fluid"
            }
          },
          totalInputPerSecond = 100,
          treeDepth = 3,
          type = "fluid",
          unitsPerSecond = 50
        }
      },
      inputPerSecond = 0.5,
      name = "battery",
      products = {
        {
          amount = 1,
          name = "battery",
          probability = 1,
          type = "item"
        }
      },
      totalInputPerSecond = 5,
      treeDepth = 2,
      type = "item",
      unitsPerSecond = 0.25
    },
    {
        amount = 5,
      assemblers = 20,
      craftingTime = 4,
      ingredients = {
        {
            amount = 5,
            assemblers = 20,
            craftingTime = 4,
            inputPerSecond = 0.5,
            name = "Mystery Input",
            products = {
                {
                amount = 1,
                name = "Mystery Item",
                probability = 1,
                type = "item"
                }
            },
            totalInputPerSecond = 5,
            treeDepth = 3,
            type = "item",
            unitsPerSecond = 0.25
        }
      },
      inputPerSecond = 0.5,
      name = "Mystery Item",
      products = {
        {
          amount = 1,
          name = "Mystery Item",
          probability = 1,
          type = "item"
        }
      },
      totalInputPerSecond = 5,
      treeDepth = 2,
      type = "item",
      unitsPerSecond = 0.25
    },
  },
  name = "accumulator",
  products = {
    {
      amount = 1,
      name = "accumulator",
      probability = 1,
      type = "item"
    }
  },
  treeDepth = 1,
  unitsPerSecond = 0.1
}

-- printDepTree(t)
local dependencyTree = formatDepTree({recipe=t})
for index, value in ipairs(dependencyTree) do
    print(value)
end

local string = "1234"
print(replaceAt(string, 2, "two"))