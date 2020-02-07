# MinimapAPI
MinimapAPI is a modding API developed for the game "The Binding of Isaac: Rebirth". Its purpose is to provide a framework that allows other modders to freely edit the ingame Minimap as they please.

When downloading, please make sure to delete your save*.dat files (if you downloaded this previously) and put this in a folder beginning with an exclamation mark (ie !MinimapAPI)

### Unique Features
* Dynamically resizable minimap
* Over 30 new unique custom icons for pickups, slot machines and beggars
* Highly configurable: Turn on/off parts of the minimap, like shadows or icons
* Smooth minimap movement (1.0 is instant, 0.1 is very slow)
* New map mode: Small full map (display all rooms in small form!)

### API Features
* Add/remove rooms from the minimap
* Custom pickups
* Custom icons
* Automatic pickup detection
* Custom color rooms

### Documentation
Go to the wiki section or [click here](https://github.com/TazTxUK/MinimapAPI/wiki)

## Backlog / Todo-List
### Planned Features:
* New Setting: Map Transparency
* Display mode: Vanilla Borderless
* Add Map Curse Icons (restock, curses)
  * Change position of the Map Curse icons (left, bottom[vanilla])
* Function - getRandomFreePos() : Returns a X,Y Position, where no room is present but thats adjcent to an existing room (useful for Red Key-like features)
* Disable Room and Pickup icons seperately
* Add pickup display config options: (One pickup per item group, one pickup per corresponding icon, show all)
* Draw new pickup icons (where applicable):
  * Trapdoor (Grid Entity icons not implemented)
* Hovering over a room will display a list of its contents *(Thanks JSG!)*

### Known issues:
* Curse of the Lost questionmark isnt drawn
* See [Issues](https://github.com/TazTxUK/MinimapAPI/issues)

### Needs rework:
* Some comments for the functions with a small explaination on what they are used for, what arguments they require, which of them are optional and what the function returns
