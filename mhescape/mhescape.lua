---------------------
--   Addon Info
---------------------
_addon.name = 'MogHouseEscape'
_addon.author = 'Proton'
_addon.commands = {'mhe'}
_addon.version = '2023.05.28.alpha'

---------------------
--   Requires
---------------------
packets = require('packets')
require('sendall')
windowerRes_zones = require('resources').zones

-----------------------------------
--   Full Scope Addon Variables
-----------------------------------

local needToConfirm = false
local suppressClientConfirm = false
local residentialZoneIDs = {
    sandoria = {230, 231, 232},
    bastok = {234, 235, 236},
    windurst = {238, 239, 240, 241},
    jeuno = {243, 244, 245, 246},
    ahturhgan = {48, 50},
    past = {80, 87, 94},
    adoulin = {256, 257}
}
local destinationMatrix = {
    sandoria = {
        exit = {region = 1, zone = 0},
        south = {region = 1, zone = 1},
        north = {region = 1, zone = 2},
        port = {region = 1, zone = 3},
        secondFloor = {region = 1, zone = 125},
        firstFloor = {region = 1, zone = 126},
        garden = {region = 1, zone = 127}
    },
    bastok = {
        exit = {region = 2, zone = 0},
        mines = {region = 2, zone = 1},
        markets = {region = 2, zone = 2},
        port = {region = 2, zone = 3},
        secondFloor = {region = 2, zone = 125},
        firstFloor = {region = 2, zone = 126},
        garden = {region = 2, zone = 127}
    },
    windurst = {
        exit = {region = 3, zone = 0},
        waters = {region = 3, zone = 1},
        walls = {region = 3, zone = 2},
        port = {region = 3, zone = 3},
        woods = {region = 3, zone = 4},
        secondFloor = {region = 3, zone = 125},
        firstFloor = {region = 3, zone = 126},
        garden = {region = 3, zone = 127}
    },
    jeuno = {
        exit = {region = 4, zone = 0},
        rulude = {region = 4, zone = 1},
        upper = {region = 4, zone = 2},
        lower = {region = 4, zone = 3},
        port = {region = 4, zone = 4},
        secondFloor = {region = 4, zone = 125},
        firstFloor = {region = 4, zone = 126},
        garden = {region = 4, zone = 127}
    },
    ahturhgan = {
        exit = {region = 5, zone = 0},
        alzahbi = {region = 5, zone = 1},
        whitegate = {region = 5, zone = 2},
        garden = {region = 5, zone = 127}
    },
    past = {
        exit = {region = 0, zone = 0}
    },
    adoulin = {
        exit = {region = 9, zone = 0},
        western = {region = 9, zone = 1},
        eastern = {region = 9, zone = 2},
        garden = {region = 9, zone = 127}
    }
}

---------------------
--   Addon Functions
---------------------

local function menuDisposition()
    -- todo: determine possible formats for 0x05E based on quest completion
    --      1) no exit quests
    --      2a) exit quest but no mog garden
    --      2b) exit quest and mog garden
    -- Think about how to check for 2nd floor status, and tell which floor we are currently on.
    --      No support for switching floors for now
end

-- sends 0x05E to initiate MH Exit
local function sendExit(argRegion, argZone)
    if argRegion and argZone then
        local data = {
            -- Whith this code, why does _unknown1 start with a 3 when captured with PV?
            -- |  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F      | 0123456789ABCDEF
            -- -----------------------------------------------------  ----------------------
            --  0 | 5E 0C 00 00 7A 6D 72 71 30 00 00 00 00 00 00 00    0 | ^...zmrq0.......
            --  1 | 00 00 00 00 00 00 00 00 -- -- -- -- -- -- -- --    1 | ........--------

            ['Zone Line'] = 1903324538,
            ['_unknown1'] = 0,
            ['_unknown2'] = 0,
            ['_unknown3'] = argRegion,
            ['Type'] = argZone,
        }

        --make sure the packets look right before sending bad data to SE
        --[[for key, value in pairs(data) do
            print(key, value)
        end]]

        local exitPacket = packets.new('outgoing', 0x05E, data)
        packets.inject(exitPacket)
        needToConfirm = true
        suppressClientConfirm = true
    else
        print('Invalid request')
    end
end

-- client will send the 0x00D on its own, to respond to the server's 0x00B. But if we inject the 0x05E the 0x00D isn't formatted right.
-- On MH exit, the 0x00D should have _unknown3 = R and _unknown4 = Q. When we inject 0x05E and let the client respond it sends all 0s for 0x00D
-- Todo: intercept and augment 0x00D to be formatted as below.
local function confirmExit()
    
    local data = {
        ['_unknown1'] = 0x00,
        ['_unknown2'] = 0x00,
        ['_unknown3'] = 0x72,
        ['_unknown4'] = 0x71,
    }

    local confirmPacket = packets.new('outgoing', 0x00D, data)
    packets.inject(confirmPacket)
    needToConfirm = false
end

-- using windower.ffxi.get_info().zone and the arguments supplied by the user for desired exit destination, return the appropriate parameters to create packet 0x05E
local function determineExitPacketParams(argRequestedExit)
    local currentZoneID = windower.ffxi.get_info().zone
    local currentZone = nil

    for zone, ids in pairs(residentialZoneIDs) do
        for _, id in ipairs(ids) do
            if id == currentZoneID then
                currentZone = zone
                break
            end
        end
        if currentZone then
            break
        end
    end

    local destinationTable = destinationMatrix[currentZone]
    if destinationTable then
        local chosenRow = nil
        for key, data in pairs(destinationTable) do
          if key == argRequestedExit then
            chosenRow = data
            break
          end
        end
      
        if chosenRow then
            local destinationRegion = chosenRow.region
            local destinationZone = chosenRow.zone
          
            return destinationRegion, destinationZone
        else
          -- Print error message and stop executing
          print("Invalid user input")
          return nil, nil
        end
    else
        -- Print error message and stop executing
        print("Wrong region for that destination")
        return nil, nil
    end
end

---------------------
--   Addon Commands
---------------------

local commands = {}

--exit the MH, either to where you entered (no args), or specify a location (1 arg)
commands.exit = function(argRequestedExit)
    if not argRequestedExit then
        argRequestedExit = 'exit'
    end

    if windower.ffxi.get_info().mog_house then
        local region, zone = determineExitPacketParams(argRequestedExit)
        sendExit(region, zone)
    else
        print('You must be in a Mog House')
    end
end
commands.e = commands.exit

commands.help = function()
    print("Todo: Write help info")
end

---------------------
--   Windower Events
---------------------

windower.register_event('incoming chunk', function(id,data,modified,injected,blocked)
    if id == 0x00B and needToConfirm then
        confirmExit()
    end
end)

windower.register_event('outgoing chunk', function(id,data,modified,injected,blocked)
    if id == 0x00D and suppressClientConfirm then
        suppressClientConfirm = false
        return true
    end
end)

-- accepts the command from the user, and however many arguments are passed. calls the appropriate command function based on the first arg
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'

    if commands[command] then
        commands[command](...)
    else
        commands.help()
    end
end)
