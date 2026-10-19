local function log(message)
    if Config.Debug then
        print(('[len_rollover] %s'):format(message))
    end
end

local function reply(source, kind, title, description)
    if source == 0 then
        print(('[len_rollover] %s: %s'):format(title, description))
        return
    end

    TriggerClientEvent('len_rollover:notify', source, kind, title, description)
end

local function resolveTarget(source, arg)
    if arg == nil then
        if source ~= 0 then
            return source
        end
        return nil
    end

    local id = tonumber(arg)
    if not id or math.type(id) ~= 'integer' then
        return nil
    end

    return id
end

local function validateTarget(source, arg)
    local targetId = resolveTarget(source, arg)
    if not targetId then
        return nil, L('invalid_id')
    end

    if GetPlayerName(targetId) == nil then
        return nil, L('player_not_found', targetId)
    end

    return targetId
end

if Config.Commands.resetflip.enabled then
    RegisterCommand(Config.Commands.resetflip.name, function(source, args)
        local targetId, err = validateTarget(source, args[1])
        if not targetId then
            reply(source, 'error', L('title_error'), err)
            return
        end

        TriggerClientEvent('len_rollover:reset', targetId)
        TriggerClientEvent('len_rollover:notify', targetId, 'success', L('reset_title'), L('reset_target'))

        if source ~= targetId then
            reply(source, 'success', L('title_success'), L('reset_admin', targetId))
        end

        log(('Rollover reset for %s by %s'):format(targetId, source))
    end, Config.Commands.resetflip.restricted)
end

if Config.Commands.tflip.enabled then
    RegisterCommand(Config.Commands.tflip.name, function(source, args)
        local targetId, err = validateTarget(source, args[1])
        if not targetId then
            reply(source, 'error', L('title_error'), err)
            return
        end

        TriggerClientEvent('len_rollover:forceFlip', targetId)
        reply(source, 'success', L('title_success'), L('tflip_admin', targetId))

        log(('Force flip on %s by %s'):format(targetId, source))
    end, Config.Commands.tflip.restricted)
end
