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
        set_candidate(belt_name, {
            belt.related_underground_belt and belt.related_underground_belt.name,
            string.gsub(belt_name, "%-belt", "-underground-belt"),
        })
    end

    for pipe_name, _ in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "pipe" } })) do
        set_candidate(pipe_name, { pipe_name .. "-to-ground" })
    end

    return conversions
end

local conversions = calculate_conversions()

local function get_controller_features(player)
    local controllers = {
        [defines.controllers.character] = { has_items = true, free_items = false },
        [defines.controllers.editor] = { has_items = true, free_items = true },
    }
    return controllers[player.controller_type] or { has_items = false, free_items = false }
end

local function perform_toggle(event)
    local player = game.get_player(event.player_index)

    local item_name, quality
    if player.cursor_stack and player.cursor_stack.valid_for_read then
        item_name = player.cursor_stack.name
        quality  = player.cursor_stack.quality
    elseif player.cursor_ghost then
        item_name = player.cursor_ghost.name.name
        quality = player.cursor_ghost.quality
    else
        return
    end
    local other_name = conversions[item_name]
    if not other_name then
        return
    end
    local other_item_with_quality = { name = other_name, quality = quality }

    player.clear_cursor()

    local controller_features = get_controller_features(player)
    if controller_features.has_items then
        local stack, slot = player.get_main_inventory().find_item_stack(other_item_with_quality)
        if stack then
            player.cursor_stack.transfer_stack(stack)
            player.hand_location = { inventory = defines.inventory.character_main, slot = slot }
        elseif controller_features.free_items then
            other_item_with_quality.count = prototypes.item[other_name].stack_size
            player.cursor_stack.set_stack(other_item_with_quality)
        else
            player.cursor_ghost = other_item_with_quality
        end
    else
        player.cursor_ghost = other_item_with_quality
    end
end

script.on_event("tbl-toggle", perform_toggle)
