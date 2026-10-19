local flipId = 0
local isHandlingFlip = false
local noFlipEnabled = false
local detectionStartedAt = nil
local FLIP_KEY = 'flip'
local effectsAppliedId = 0
local effectsAppliedAt = 0
local repairedVehicle = nil

local function debugLog(message)
    if Config.Debug then
        print(('[len_rollover] %s'):format(message))
    end
end

local immuneClasses = {}
for _, class in ipairs(Config.Immunity.vehicleClasses) do
    immuneClasses[class] = true
end

local immuneModels = {}
for _, model in ipairs(Config.Immunity.models) do
    immuneModels[GetHashKey(model)] = true
end

debugLog('Client loaded, locale: ' .. Config.Locale)

local function notify(kind, title, description, duration, key)
    SendNUIMessage({
        action = 'notify',
        kind = kind,
        title = title,
        description = description,
        duration = duration or Config.UI.defaultDuration,
        key = key,
    })
end

local function dismissNotice(key)
    SendNUIMessage({ action = 'dismiss', key = key })
end

local function isUpsideDown(vehicle)
    local pitch = math.rad(GetEntityPitch(vehicle))
    local roll = math.rad(GetEntityRoll(vehicle))
    local upZ = math.cos(pitch) * math.cos(roll)
    local rollCheck = math.abs(GetEntityRoll(vehicle)) > Config.Detection.rollThreshold
    return upZ < Config.Detection.upsideDownThreshold or rollCheck
end

local function isImmune(vehicle)
    if immuneClasses[GetVehicleClass(vehicle)] then
        return true
    end

    if immuneModels[GetEntityModel(vehicle)] then
        return true
    end

    local plate = (GetVehicleNumberPlateText(vehicle) or ''):upper():match('^%s*(.-)%s*$')
    for _, prefix in ipairs(Config.Immunity.platePrefixes) do
        if plate:sub(1, #prefix) == prefix:upper() then
            return true
        end
    end

    return false
end

local function isRepaired(vehicle)
    if effectsAppliedAt == 0 or GetGameTimer() - effectsAppliedAt < Config.Detection.repairGraceTime then
        return false
    end

    return GetVehicleEngineHealth(vehicle) > Config.Detection.repairEngineThreshold
end

local function isActive(vehicle, id)
    local ped = PlayerPedId()
    return id == flipId
        and DoesEntityExist(vehicle)
        and not IsPedDeadOrDying(ped, true)
        and GetVehiclePedIsIn(ped, false) == vehicle
        and not (effectsAppliedId == id and isRepaired(vehicle))
end

local function waitActive(vehicle, id, ms)
    local endTime = GetGameTimer() + ms
    while GetGameTimer() < endTime do
        if not isActive(vehicle, id) then
            return false
        end
        Wait(100)
    end
    return isActive(vehicle, id)
end

local function setVisibility(vehicle, visible)
    if Config.Damage.preventVisualDamage and DoesEntityExist(vehicle) then
        SetVehicleCanBeVisiblyDamaged(vehicle, visible)
    end
end

local function endFlip(vehicle, id)
    if id ~= flipId then
        return
    end

    if DoesEntityExist(vehicle) and effectsAppliedId == id then
        debugLog(('Episode end, engine health: %.1f, repaired: %s'):format(
            GetVehicleEngineHealth(vehicle), tostring(isRepaired(vehicle))))
        if isRepaired(vehicle) then
            repairedVehicle = vehicle
        end
    end

    isHandlingFlip = false
    dismissNotice(FLIP_KEY)
    if DoesEntityExist(vehicle) then
        setVisibility(vehicle, true)
    end
    debugLog('Flip episode ended')
end

local function tryIgnite(vehicle, id)
    if not Config.Fire.enabled then
        return
    end

    if math.random(1, 100) > Config.Fire.chance then
        return
    end

    if not waitActive(vehicle, id, Config.Fire.delay) then
        return
    end

    if Config.Fire.target == 'player' then
        StartEntityFire(PlayerPedId())
    else
        StartEntityFire(vehicle)
    end
end

local function handleFlip(vehicle)
    flipId = flipId + 1
    local id = flipId
    isHandlingFlip = true
    debugLog('Flip handling started')

    local ped = PlayerPedId()
    if Config.Effects.armorLoss > 0 then
        SetPedArmour(ped, math.max(GetPedArmour(ped) - Config.Effects.armorLoss, 0))
    end

    local shakeEnd = GetGameTimer() + Config.Effects.shake.duration
    while GetGameTimer() < shakeEnd and isActive(vehicle, id) do
        ShakeGameplayCam(Config.Effects.shake.type, Config.Effects.shake.intensity)
        Wait(100)
    end
    StopGameplayCamShaking(true)

    if not isActive(vehicle, id) then
        endFlip(vehicle, id)
        return
    end

    notify('error', L('flip_title'), L('flip_desc'), Config.Effects.notifyDuration, FLIP_KEY)

    if Config.Effects.sound.enabled then
        TriggerEvent(Config.Effects.sound.event, Config.Effects.sound.name, Config.Effects.sound.volume)
    end

    SetVehicleEngineHealth(vehicle, Config.Damage.engineHealthAfterFlip)
    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleUndriveable(vehicle, true)
    setVisibility(vehicle, false)
    effectsAppliedId = id
    effectsAppliedAt = GetGameTimer()

    if not waitActive(vehicle, id, Config.Damage.lockDuration) then
        endFlip(vehicle, id)
        return
    end

    tryIgnite(vehicle, id)

    local righted = false
    while isActive(vehicle, id) do
        if not righted and not isUpsideDown(vehicle) then
            righted = true
            isHandlingFlip = false
            if Config.Damage.autoRepairOnUpright then
                SetVehicleUndriveable(vehicle, false)
                SetVehicleEngineHealth(vehicle, Config.Repair.engineHealth)
            end
            setVisibility(vehicle, true)
            debugLog('Vehicle righted')
        end
        Wait(250)
    end

    endFlip(vehicle, id)
end

CreateThread(function()
    while true do
        local sleep = Config.Detection.idleInterval
        local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if repairedVehicle and (currentVehicle ~= repairedVehicle
            or not DoesEntityExist(repairedVehicle)
            or not isUpsideDown(repairedVehicle)) then
            repairedVehicle = nil
        end

        if not isHandlingFlip and not noFlipEnabled then
            local vehicle = currentVehicle

            if vehicle ~= 0 then
                sleep = Config.Detection.checkInterval

                local upsideDown = isUpsideDown(vehicle)
                if upsideDown then
                    debugLog(('Upside down detected (immune: %s)'):format(tostring(isImmune(vehicle))))
                end

                if upsideDown and not isImmune(vehicle) and repairedVehicle ~= vehicle then
                    detectionStartedAt = detectionStartedAt or GetGameTimer()

                    if GetGameTimer() - detectionStartedAt >= Config.Detection.debounceTime then
                        detectionStartedAt = nil
                        CreateThread(function()
                            handleFlip(vehicle)
                        end)
                    end
                else
                    detectionStartedAt = nil
                end
            else
                detectionStartedAt = nil
            end
        end

        Wait(sleep)
    end
end)

if Config.Commands.noflip.enabled then
    RegisterCommand(Config.Commands.noflip.name, function()
        noFlipEnabled = not noFlipEnabled

        if noFlipEnabled then
            notify('warning', L('noflip_title'), L('noflip_on'))
        else
            notify('info', L('noflip_title'), L('noflip_off'))
        end
    end, false)
end

RegisterNetEvent('len_rollover:notify', function(kind, title, description, duration)
    notify(kind, title, description, duration)
end)

RegisterNetEvent('len_rollover:reset', function()
    flipId = flipId + 1
    isHandlingFlip = false
    detectionStartedAt = nil
    repairedVehicle = nil
    dismissNotice(FLIP_KEY)

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        return
    end

    SetVehicleEngineHealth(vehicle, Config.Repair.engineHealth)

    local bodyHealth = GetVehicleBodyHealth(vehicle)
    SetVehicleBodyHealth(vehicle, math.min(bodyHealth + Config.Repair.bodyHealthBonus, Config.Repair.bodyHealthMax))

    if isUpsideDown(vehicle) then
        local coords = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        SetEntityRotation(vehicle, 0.0, 0.0, heading, 2, true)
        SetEntityCoords(vehicle, coords.x, coords.y, coords.z + Config.Repair.liftOffset, false, false, false, true)
    end

    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    setVisibility(vehicle, true)
end)

RegisterNetEvent('len_rollover:forceFlip', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        return
    end

    local rotation = GetEntityRotation(vehicle, 2)
    local startPitch, roll, yaw = rotation.x, rotation.y, rotation.z
    local steps = Config.ForceFlip.steps

    CreateThread(function()
        for i = 1, steps do
            if not DoesEntityExist(vehicle) then
                return
            end

            local pitch = startPitch + (Config.ForceFlip.targetPitch - startPitch) * (i / steps)
            SetEntityRotation(vehicle, pitch, roll, yaw, 2, true)
            Wait(Config.ForceFlip.stepDelay)
        end
    end)
end)

RegisterNUICallback('ready', function(_, cb)
    cb(Config.UI)
end)
