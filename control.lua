local function calculate_conversions()
    local conversions = {}

    local function set_candidate(name, candidate_names)
        for _, candidate_name in pairs(candidate_names) do
            if candidate_name and prototypes.entity[candidate_name] then
                conversions[name] = candidate_name
                conversions[candidate_name] = name
                return
            end
        end
    end

    for belt_name, belt in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "transport-belt" } })) do
        local candidates = { belt.related_underground_belt.name, string.gsub(belt_name, "%-belt", "-underground-belt") }
        set_candidate(belt_name, candidates)
    end

    for pipe_name, _ in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "pipe" } })) do
        set_candidate(pipe_name, { pipe_name .. "-to-ground" })
    end

    return conversions
end

local conversions = calculate_conversions()


local function get_controller_features(player)
    local controllers = {
        [defines.controllers.character] = {has_items = true, free_items = false},
        [defines.controllers.editor] = {has_items = true, free_items = true},
    }
    return controllers[player.controller_type] or {has_items = false, free_items = false}
end

local function perform_toggle(event)
    local player = game.get_player(event.player_index)

    local item_type
    if player.cursor_stack and player.cursor_stack.valid_for_read then
        item_type = player.cursor_stack.name
    elseif player.cursor_ghost then
        item_type = player.cursor_ghost.name.name
    end

    local other_type = conversions[item_type]
    if not other_type then
        return
    end

    local controller_features = get_controller_features(player)

    player.clear_cursor()
    if controller_features.has_items then
        local stack, slot = player.get_main_inventory().find_item_stack(other_type)
        if stack then
            player.cursor_stack.transfer_stack(stack)
            player.hand_location = { inventory = defines.inventory.character_main, slot = slot }
        elseif controller_features.free_items then
            player.cursor_stack.set_stack({ name = other_type, count = prototypes.item[other_type].stack_size })
        end
    else
        player.cursor_ghost = other_type
    end
end

script.on_event("tbl-toggle", perform_toggle)
