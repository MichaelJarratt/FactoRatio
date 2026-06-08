# FactoRatio

FactoRatio is the factorio mod with which you can plan the entire input chain for the desired production type and volume.

## Output Example
`/getrecipe accumulator`

```
 accumulator Assemblers: 10
   iron-plate Assemblers: 7 (Producing 2 per second, or 0.2 per assembler)
       iron-ore units /s 2.1875 (0.3125 per producer)
   battery Assemblers: 20 (Producing 5 per second, or 0.5 per assembler)
     iron-plate Assemblers: 16 (Producing 5 per second, or 0.25 per assembler)
         iron-ore units /s 5 (0.3125 per producer)
     copper-plate Assemblers: 16 (Producing 5 per second, or 0.25 per assembler)
         copper-ore units /s 5 (0.3125 per producer)
     sulfuric-acid Assemblers: 2 (Producing 100 per second, or 5 per assembler)
       iron-plate Assemblers: 7 (Producing 2 per second, or 1 per assembler)
           iron-ore units /s 2.1875 (0.3125 per producer)
       sulfur Assemblers: 5 (Producing 10 per second, or 5 per assembler)
           water units /s 150 (30 per producer)
           petroleum-gas units /s 150 (30 per producer)
         water units /s 200 (100 per producer)
```

# Project Goals
I want the mod to have two aspects, first a pretty-printed console output, second a custom UI showing a more interactive version of the pretty-printed information.

# Changelog
*only signifcant changes logged here*

## 08/06/2026 - Pretty Printed Output
- [ ] Mercury
>Significant updated to the way trees are build and structures, now there is less waste and the tree is easier to navigate.
>Formatted the output to pretty print, see below.
>```
> iron-gear-wheel Assemblers: 1
>   iron-plate Assemblers: 13 (Producing 4 per second, or 4 per assembler)>
>       iron-ore units /s 4.0625 (0.3125 per producer)
>```
>### Further Ambitions
>- [ ] Display flattened output under the tree. e.g. total number of assemblers / smelters of each type
>- [ ] Name producers appropriately for the recipe. e.g. iron-plate should be displayed as being produced by furnaces
>- [ ] Display number of drills required to achieve the required raw resource input
>- [ ] Handle advanced oil processing *
>
>\* Because of the way recipe search is implemented (looking for the name of the item in prototypes.recipe), advanced oil processing products are found to have "no recipe" and are treated as a base resource (e.g. ores, crude oil, water). There are probably other recipes that are affected this way.

## 07/06/2026 - MVP
>Created mod MVP.
>
>/getRecipe \<item name> \<production per second> <br>
>Recursively builds nested tables of recipes and then recursively prints that table and the number of required assemblers to the factorio game log.<br>
>The output is very not pretty and difficult to parse out the useful information, the next commits will be cleaning up this output.