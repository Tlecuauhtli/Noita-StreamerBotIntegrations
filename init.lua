
---@type boolean
local initialized
---@type boolean
local active
---@type boolean, boolean
local is_dead, paused
---@type integer, integer, integer
local starting_time, ending_time, next_poll
---@type integer, integer
local time_paused, starting_time_paused
---@type table
local voteGUI
---@type boolean
local connected = false
local count = 0
---@type table
local current_events = {}
---@type table
local current_voters = {}
---@type table
local total_votes = {}


-- Utility functions
local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '\"' .. k .. '\"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ', '
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

dofile_once("data/scripts/streaming_integration/event_list.lua")

local function handle_poll()
    local current_time = os.clock()
    if not active and not paused and current_time > (next_poll + time_paused) then
        starting_time = current_time
        ending_time = current_time + tonumber(ModSettingGet("streamerboti.voting_time"))
        time_paused = 0
        active = true
        current_events = {}
        _ws_send("{ \"request\": \"GetActiveViewers\",\"id\": \"<id>\"}")
        _streaming_on_vote_start()
        for i = 1, ModSettingGet("streamerboti.voting_n"), 1 do
            local eventId, uiName, uiDescription, uiIcon = _streaming_get_event_for_vote()
            local eventData = {
                id = eventId,
                ui_name = uiName,
                ui_description = uiDescription,
                ui_icon = uiIcon
            }
            table.insert(current_events, 1, eventData)
        end
        print("Selected events: " .. dump(current_events))
        print("Vote started")
    end
    if active and not paused and current_time > (ending_time + time_paused) then
        print("Vote end")
        _ws_send("{ \"request\": \"GetActiveViewers\",\"id\": \"<id>\"}")
        GuiDestroy(voteGUI)
        voteGUI = nil
        active = false
        time_paused = 0
        next_poll = current_time + tonumber(ModSettingGet("streamerboti.voting_cooldown"))
        local no_vote = true
        local highest = -1
        for k, v in pairs(total_votes) do
            if v > 0 then
                no_vote = false
            end
            if v > highest then
                highest = v
            end
        end
        if not no_vote then
            local draw = {}
            for k, v in pairs(total_votes) do
                if highest == v then
                    table.insert(draw, 1, k )
                end
            end
            print("Chosen: " .. dump(draw))
            local count = 0
            for _ in pairs(draw) do count = count + 1 end
            local winner = Random(1,count)
            print("Winner: " .. draw[winner])
            _streaming_run_event(current_events[draw[winner]]["id"])
            
            GamePrintImportant(
                GameTextGetTranslatedOrNot(current_events[draw[winner]].ui_name),
                GameTextGetTranslatedOrNot(current_events[draw[winner]].ui_description)
            )

        end
        if no_vote and ModSettingGet("streamerboti.random_no_vote") then
            local count = 0
            for _ in pairs(current_events) do count = count + 1 end
            local winner = Random(1,count)
            print("Winner: [" .. winner .. "] " .. dump(current_events[winner]))
            GamePrintImportant(
                GameTextGetTranslatedOrNot(current_events[winner].ui_name),
                GameTextGetTranslatedOrNot(current_events[winner].ui_description)
            )
            _streaming_run_event(current_events[winner]["id"])
        end
        
        current_voters = {}
        total_votes = {}

    end
    if not active and not paused then
        local time_to_next = math.floor((next_poll + time_paused) - current_time)
        
        if GameIsInventoryOpen() then
            
            voteGUI = voteGUI or GuiCreate()
            GuiStartFrame(voteGUI)
            
            GuiLayoutBeginVertical(voteGUI, 4, 85)
            GuiBeginAutoBox( voteGUI )
            GuiOptionsAdd(voteGUI, 2) 
            GuiZSet( voteGUI, -8000 ) 
            GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)   
            GuiText(voteGUI, 0, 0, "Next vote in: " .. time_to_next)
            GuiZSetForNextWidget( voteGUI, -700 )
            GuiEndAutoBoxNinePiece( voteGUI, 5, 0, 0, false, 0, "data/ui_gfx/decorations/9piece0_gray2.png", "data/ui_gfx/decorations/9piece0_gray2.png" )
            GuiLayoutEnd(voteGUI)
        else

            voteGUI = voteGUI or GuiCreate()
            GuiStartFrame(voteGUI)
            
            GuiLayoutBeginVertical(voteGUI, 4, 15)
            GuiBeginAutoBox( voteGUI )
            GuiOptionsAdd(voteGUI, 2) 
            GuiZSet( voteGUI, -8000 ) 
            GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)   
            GuiText(voteGUI, 0, 0, "Next vote in: " .. time_to_next)
            GuiZSetForNextWidget( voteGUI, -700 )
            GuiEndAutoBoxNinePiece( voteGUI, 5, 0, 0, false, 0, "data/ui_gfx/decorations/9piece0_gray2.png", "data/ui_gfx/decorations/9piece0_gray2.png" )
            GuiLayoutEnd(voteGUI)
        end
        
    end
    if active and not paused then
        
        local remaining = math.floor((ending_time + time_paused) - current_time)
        local showVotes = ModSettingGet("streamerboti.show_votes")
        voteGUI = voteGUI or GuiCreate()

        if GameIsInventoryOpen() then 
            GuiStartFrame(voteGUI)
            GuiLayoutBeginHorizontal(voteGUI, 4, 85)
            GuiBeginAutoBox( voteGUI )
            GuiOptionsAdd(voteGUI, 2) 
            GuiZSet( voteGUI, -8000 ) 
            GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)   
            GuiText(voteGUI, 0, 0, "(" .. remaining .. ")" .. " Vote for one: ")
            for i, v in ipairs(current_events) do
                local votes = total_votes[i]
                if votes == nil then
                    votes = 0
                end
                GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)
                if showVotes then
                    GuiText(voteGUI, 0, 0, " | (" .. votes ..") " .. i .. " - " .. GameTextGetTranslatedOrNot(v["ui_name"]))
                else
                    GuiText(voteGUI, 0, 0, " | ( ? ) " .. i .. " - " .. GameTextGetTranslatedOrNot(v["ui_name"]))
                end
                
            end
            GuiZSetForNextWidget( voteGUI, -700 )
            GuiEndAutoBoxNinePiece( voteGUI, 5, 0, 0, false, 0, "data/ui_gfx/decorations/9piece0_gray.png", "data/ui_gfx/decorations/9piece0_gray.png" )
            GuiLayoutEnd(voteGUI)
        else
            GuiStartFrame(voteGUI)
            
            GuiLayoutBeginVertical(voteGUI, 4, 15)
            GuiBeginAutoBox( voteGUI )
            GuiOptionsAdd(voteGUI, 2) 
            GuiZSet( voteGUI, -8000 ) 
            GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)   
            GuiText(voteGUI, 0, 0, "(" .. remaining .. ")" .. " Vote for one:")
            for i, v in ipairs(current_events) do
                local votes = total_votes[i]
                if votes == nil then
                    votes = 0
                end
                GuiColorSetForNextWidget(voteGUI, 1, 1, 1, 0.5)
                GuiText(voteGUI, 0, 0, "(" .. votes ..") " .. i .. " - " .. GameTextGetTranslatedOrNot(v["ui_name"]) .. ": " .. GameTextGetTranslatedOrNot(v["ui_description"]))
            end
            GuiZSetForNextWidget( voteGUI, -700 )
            GuiEndAutoBoxNinePiece( voteGUI, 5, 0, 0, false, 0, "data/ui_gfx/decorations/9piece0_gray2.png", "data/ui_gfx/decorations/9piece0_gray2.png" )
            GuiLayoutEnd(voteGUI)
        end
    end
end

function OnModPreInit() 

end

function OnModInit() 
    
end

function OnModPostInit() 

end

function OnPlayerSpawned( player_entity ) 
	dofile("data/ws/ws.lua")
    dofile("data/ws/json.lua")
end

function OnPlayerDied( player_entity ) 

end

function OnWorldInitialized() 

end

function OnWorldPreUpdate() 

    if connected then
        handle_poll()
    end
end

function OnWorldPostUpdate() 
	if _ws_main then
        _ws_main()
        if not initialized then
            local onConnect = function(msg)
                local response = JSON:decode(msg)
                if response["request"] == "Hello" then
                    _ws_send(" { \"request\": \"Subscribe\", \"id\": \"<id>\", \"events\": { \"Twitch\": [ \"ChatMessage\" ], \"Youtube\":[ \"Message\" ], \"Custom\":[ \"CodeEvent\" ] } }")
                    connected = true
                    GamePrint("Successfully connected!")
                end
            end
            local printALL = function(msg)
                print(msg)
            end
            local handle_vote = function(msg)
                local response = JSON:decode(msg)
                if active and response["event"] ~= nil then
                    print("message recevied")
                    print("Message from: " .. response["event"]["source"])
                    local user = {}
                    local update_votes = false
                    if response["event"]["source"] == "Twitch" then
                        local res_choice = tonumber(response["data"]["message"]["message"])
                        print("Message as number: " .. res_choice)
                        if not(res_choice ~= nil and res_choice == math.floor(res_choice) and res_choice >= 0) then
                            return
                        end
                        print("It was a number!")
                        user = { 
                            ["id"] = response["data"]["message"]["userId"],
                            ["name"] = response["data"]["message"]["displayName"],
                            ["choice"] = res_choice
                        }
                        if current_voters["Twitch"] == nil then
                            current_voters["Twitch"] = {}
                        end
                        current_voters["Twitch"][user["id"]] = user
                        update_votes = true
                    end
                    if response["event"]["source"] == "YouTube" then
                        local res_choice = tonumber(response["data"]["message"])
                        if not(res_choice ~= nil and res_choice == math.floor(res_choice) and res_choice >= 0) then
                            return
                        end
                        user = { 
                            ["id"] = response["data"]["user"]["id"],
                            ["name"] = response["data"]["user"]["name"],
                            ["choice"] = res_choice
                        }
                        if current_voters["YouTube"] == nil then
                            current_voters["YouTube"] = {}
                        end
                        current_voters["YouTube"][user["id"]] = user
                        update_votes = true
                    end
                    if response["event"]["source"] == "Custom" then
                        local res_choice = tonumber(response["data"]["args"]["message"])
                        print("Message as number: " .. res_choice)
                        if not(res_choice ~= nil and res_choice == math.floor(res_choice) and res_choice >= 0) then
                            return
                        end
                        user = { 
                            ["id"] = response["data"]["args"]["userId"],
                            ["name"] = response["data"]["args"]["user"],
                            ["choice"] = res_choice
                        }
                        if current_voters["Kick"] == nil then
                            current_voters["Kick"] = {}
                        end
                        current_voters["Kick"][user["id"]] = user
                        update_votes = true
                    end
                    if update_votes then
                        total_votes = {}
                        for k, v in pairs(current_voters) do
                            for k2, v2 in pairs(v) do
                                if total_votes[v2["choice"]] == nil then
                                    total_votes[v2["choice"]] = 1
                                else
                                    total_votes[v2["choice"]] = total_votes[v2["choice"]] + 1
                                end
                            end
                        end
                        print()
                        print(dump(total_votes))
                    end
                end
            end
            local handle_active_Viewers = function(msg)
                local response = JSON:decode(msg)
                if response["viewers"] ~= nil then
                    GlobalsSetValue("ActiveViewers", msg)
                end
            end
            _ws_add_onmsg(onConnect)
            --_ws_add_onmsg(printALL)
            _ws_add_onmsg(handle_active_Viewers)
            _ws_add_onmsg(handle_vote)
            next_poll = 0
            time_paused = 0
            paused = false
            initialized = true

        end
    end
    
end

function OnBiomeConfigLoaded() 

end

function OnMagicNumbersAndWorldSeedInitialized() 

end

function OnPausedChanged( is_paused, is_inventory_pause ) 
    paused = is_paused
    if paused then
        starting_time_paused = os.clock()
    else
        time_paused = time_paused + (os.clock() - starting_time_paused)
    end
end

function OnModSettingsChanged() 

end

function OnPausePreUpdate() 

end

ModLuaFileAppend( "data/scripts/streaming_integration/event_utilities.lua", "mods/STREAMERBOTINTEGRATIONS/files/scripts/append/append_event_utilities.lua")