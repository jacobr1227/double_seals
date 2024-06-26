# Double Seals + SealAPI
A Balatro mod that introduces new seal variants that double the effects of the underlying seal.

### Supported Seals:
  - The base 4 seals: effects doubled.
  - New Orange Seal: randomly enhances 1 or 2 random cards from your hand when discarded.
  - New Silver Seal: creates 1 or 2 Spectral cards when held in hand at end of round

Requires [Balamod](https://github.com/UwUDev/balamod/) latest build & [center_hook.lua](https://github.com/nicholassam6425/balatro-mods/tree/main/balamod/apis)

Use an older release (v2.0 or less) for older Balamod releases with the old mod format.

### Other Additions:
 - ~~3 new Spectral cards that add the new Seals:~~
   - ~~Blur doubles a seal, or adds a random one~~
   - ~~Gleam and Mystic add Orange and Silver seals, respectively.~~
  
The spectral cards are not currently available with the current codebase. They will be reintroduced later, however.

### Installation
Drop the folders from the zip over in releases into %appdata%/Balatro/mods for Windows, or ~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/mods for Linux.

### API for developers (FOR BALAMOD <=V0.1.11)
The API supports the addition of new seals with just a few functions.

Run the following block (replacing necessary information) for an easy setup for your mod.
```
on_enable = function()
  add_seal("SealId", "Seal Label Name", "color", "shadertype", { text = "descr", "iption" })
  -- Your effect code here, see the mods folder for examples of what this will look like
  inject_overrides()
end
on_disable = function()
  remove_seals()
end
```
This API also contains a function for adding infotips to other cards, such as jokers and consumeables.
Use this when creating other mods that refer to Seal items in their info text.

![Demo Reel](https://github.com/jacobr1227/double_seals/blob/main/gifs/double_seals_demo.gif)

![Demo Reel](https://github.com/jacobr1227/double_seals/blob/main/gifs/orange_silver_demo_reel.gif)
