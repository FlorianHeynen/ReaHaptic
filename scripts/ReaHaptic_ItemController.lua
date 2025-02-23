--[[
 * ReaScript Name: ReaHaptic_ItemController
 * Description: enables all items of a haptic item to move and resize together
 * Author: Florian Heynen
 * Version: 1.0
--]]

cmd_id = reaper.NamedCommandLookup("_MY_CUSTOM_SCRIPT_ID") -- Replace with your script ID

-- Toggle state tracking
state = reaper.GetToggleCommandState(cmd_id) -- Get current state

-- Set new state (toggle between 0 and 1)
new_state = state == 1 and 0 or 1
reaper.SetToggleCommandState(0, cmd_id, new_state)

-- Refresh toolbar to update icon
reaper.RefreshToolbar2(0, cmd_id)

-- Configuration
local parent_track_name = "haptics" -- Name of the parent track

-- Stores the state of items for comparison
local item_states = {}

function round(num, decimal_places)
    local mult = 10^(decimal_places or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Function to get a track by name
function get_track_by_name(name)
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if track_name == name then
            return track
        end
    end
    return nil
end

-- Function to store the state of items in a track
function store_item_states(track)
    local states = {}
    local item_count = reaper.CountTrackMediaItems(track)
    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        states[#states + 1] = { item = item, position = position, length = length }
    end
    return states
end

-- Function to check for changes in item states
function check_for_changes(old_states, track)
    local new_states = store_item_states(track)
    local changed = false
    for i, new_state in ipairs(new_states) do
        if not old_states[i] or 
           new_state.position ~= old_states[i].position or 
           new_state.length ~= old_states[i].length then
            changed = true
            
        end
    end
    return changed, new_states
end

local function get_item_notes(item)
    local retval, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
    return notes
end

local function sync_positionAndLength(item, ref_item)
    local ref_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
    local ref_length = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")

    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    if round(ref_pos,4) ~= round(pos,4) then
        reaper.SetMediaItemLength(item, ref_pos, false)
    end
    if round(ref_length,4) ~= round(length,4) then
        reaper.SetMediaItemPosition(item, ref_length, false)
    end
end

function findAndSync_matching_items()
    local num_selected_items = reaper.CountSelectedMediaItems(0)
    
    for i = 0, num_selected_items - 1 do
        local reference_item = reaper.GetSelectedMediaItem(0, i)
    
        reference_groupId = reaper.GetMediaItemInfo_Value(reference_item, "I_GROUPID")
        
        local num_items = reaper.CountMediaItems(0)
        for i = 0, num_items - 1 do
            local item = reaper.GetMediaItem(0, i)
            if item ~= reference_item then -- Skip the reference item
                item_groupId = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
                if item_groupId == reference_groupId then
                    if item and reference_item then
                        reaper.SetMediaItemSelected(item, true)
                        sync_positionAndLength(item, reference_item)
                    end
                end
            end
        end
    end
end

local function get_selected_items()
    local selected_items = {}
    local num_selected_items = reaper.CountSelectedMediaItems(0)
    
    for i = 0, num_selected_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(selected_items, item)
    end
    
    return selected_items
end

-- Main loop
function main()
    _, _, _, cmd_id = reaper.get_action_context()
    reaper.SetToggleCommandState(0, cmd_id, 1)
    reaper.RefreshToolbar2(0, cmd_id)

    findAndSync_matching_items()
    reaper.defer(main) -- Continue the loop
end

-- Initialize and start
local parent_track = get_track_by_name(parent_track_name)
item_states = store_item_states(parent_track)
reaper.defer(main)

function on_script_exit()
    reaper.SetToggleCommandState(0, cmd_id, 0) -- Reset toggle state
    reaper.RefreshToolbar2(0, cmd_id) -- Refresh toolbar
end

reaper.atexit(on_script_exit)