# mineTurtle 
Computercraft turtle for mining connected resources.

### Turtle abilities:
- go in straight line until find resource
- collect all connected items then return to base
- can config items name to find and item name after mine
- check if in inventory is enought space for new items - if not return to base
- check if is enought fuel to continue mining - if not return to base
- can refuel from 16th slot
- saving created by turtle map and current turtle cords to file
- if file with map and turtle cords exist turle load it on start
- can set radious of secure fields - turtle cannot mining it
-  store only mine blocks (except 16th slot for fuel):
    - throw away unwanted items
    - after collecting 16 item turtle place them on all slots
- can charge if in base is charger (next to start position)
- after charged turtle start again find resources
- put collected items into chest (below start position)
