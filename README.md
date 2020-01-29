# MinimapAPI
MinimapAPI is a modding API developed for the game "The Binding of Isaac: Rebirth". Its purpose is to provide a framework that allows other modders to freely edit the ingame Minimap as they please.


## Backlog / Todo-List
### Planned Features:
- New Setting: Map Transparency
- Split the Mod config settings in categories
- Display mode: Vanilla Borderless
- Add Map Curse Icons (Treasuremap, compass, blue map, restock,...)
  - Change position of the Map Curse icons (left, bottom[vanilla])
- Function - getRandomFreePos() : Returns a X,Y Position, where no room is present but thats adjcent to an existing room (useful for Red Key-like features)
- Function disable vanilla mapping behaviors like "build map on transition", "update current room"...
- Disable Room and Pickup icons seperately

### Known issues:
- Curse of the Lost questionmark isnt handles by the API in any way
- when entering an offmap room (Devil,angel,...), the map will center around a random spot on the map, rather than the last room visited 

### Needs rework:
- rework the "Post Render" functions to be less redundant (Assigned: Wofsauge)
- more intuitive names for most functions
- a more intuitive way to add a room. "t" or a table is not very intuitive to use...
- Some comments for the functions with a small explaination on what they are used for, what arguments they require, which of them are optional and what the function returns
