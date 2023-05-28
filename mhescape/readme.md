# Mog House Escape
### Exit the Mog House via addon commands

```
//mhe e(xit) (destination)

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
- Not able to block the clients default 0x00D response. Currently sending correct response AND blank response from client.
- All of the MH Exit packets are formatted assuming ALL MH Exit quests are complete and Mog Garden is unlocked. Use at your own risk if that isn't the case!

To-Do:
- See if I can track MH Exit quest status and Mog Garden availability to prevent sending inappropriate packets to server
- Configure IPC messages for multiboxing
