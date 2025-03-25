dofile_once("data/scripts/streaming_integration/event_list.lua")
dofile_once("data/ws/json.lua")

timed_out_names = {}
StreamingGetRandomViewerName = function()
	 
    local users = JSON:decode(GlobalsGetValue("ActiveViewers", "{count:0}" ))
    allowedUsers = {}
    for k, v in pairs(users["viewers"]) do
        if not v["exempt"] then
            table.insert(allowedUsers,1,v)
        end
    end

    local count = 0
    for _ in pairs(allowedUsers) do count = count + 1 end
    SetRandomSeed( GameGetFrameNum(), GameGetFrameNum() )
    local selected = Random(1,count)

	return allowedUsers[selected].display or ""
end