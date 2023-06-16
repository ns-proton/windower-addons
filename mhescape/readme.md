# Mog House Escape
### Exit the Mog House via addon commands

```
//mhe [a(ll)] e(xit) (destination)

examples:
//mhe e rulude
Assuming you are in Jeuno, will exit the Mog House to Ru'Lude Gardens

//mhe a e
You will exit, returning to the zone from which you entered, and an IPC message will be sent to the other instances of Windower you are currently running to do the same.

Destination list:

San d'Oria:
south
north
port
garden

Bastok:
mines
markets
port
garden

Windurst:
waters
walls
port
woods
garden

Jeuno:
rulude
upper
lower
port
garden

Aht Urhgan:
alzahbi
whitegate
garden

No advanced option for cities in the past. Only takes 'exit'.

Adoulin:
western
eastern
garden
```

Unresolved issues:
- Injected packet 0x05E has a malformed value in _unknown1. Doesn't seem to impact performance.
- The 0x00D that the client responds with after injecting the 0x05E isn't formatted right. My attempts to modify it (current code), or block it and inject my own have both been unsuccessful.
- All of the MH Exit packets are formatted assuming ALL MH Exit quests are complete and Mog Garden is unlocked. Use at your own risk if that isn't the case!

To-Do:
- Implement tracking of 0x00A (for MH Exit quest completion) and 0x067 to track Mog Garden and 2nd floor availability.
