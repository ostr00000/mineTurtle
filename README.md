# mineTurtle 
Computercraft turtle for mining connected resources.

### Turtle abilities:
- go to special points generated on spiral around base
- while going to points check if next to are resources
- resources can be specified in config file
- collect all connected block
- can config block name befor mine and item name after mine
- check if in inventory is enought space for new items - if not return to base
- check if is enought fuel to continue mining - if not return to base
- can refuel from 16th slot
- saving created by turtle map to file
- saving turtle status and cords to file
- if file with map and turtle status exist turle load it on start
- can set radious of secure fields - turtle cannot mining in secure area
- store only mine blocks (except 16th slot for fuel):
    - throw away unwanted items
    - after collecting 16 item turtle place them on all slots (to avoid picking up unwanted materials)
- can charge if in base is charger (next to start position)
- after charged turtle can start again find resources
- put collected items into chest (below start position)
