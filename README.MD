# FactoRatio

FactoRatio is the factorio mod with which you can plan the entire input chain for the desired production type and volume.

# Project Goals
I want the mod to have two aspects, first a pretty-printed console output, second a custom UI showing a more interactive version of the pretty-printed information.

# Changelog
*only signifcant changes logged here*

## 07/06/2026 - MVP
>Created mod MVP.
>
>/getRecipe \<item name> \<production per second> <br>
>Recursively builds nested tables of recipes and then recursively prints that table and the number of required assemblers to the factorio game log.<br>
>The output is very not pretty and difficult to parse out the useful information, the next commits will be cleaning up this output.