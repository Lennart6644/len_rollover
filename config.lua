Config = {}

Config.Locale = 'en'
Config.Debug = false

Config.Commands = {
    noflip = { enabled = true, name = 'noflip' },
    resetflip = { enabled = true, name = 'resetflip', restricted = true },
    tflip = { enabled = true, name = 'tflip', restricted = true },
}

Config.Detection = {
    checkInterval = 200,
    idleInterval = 1000,
    upsideDownThreshold = -0.5,
    rollThreshold = 135.0,
    repairEngineThreshold = 300.0,
    repairGraceTime = 2000,
    debounceTime = 600,
}

Config.Immunity = {
    vehicleClasses = { 15, 16 },
    platePrefixes = { 'ADMIN', 'TESTCAR' },
    models = {
        'blazer', 'blazer2', 'blazer3', 'blazer4', 'blazer5',
        'bruiser', 'bruiser2', 'marshall',
        'monster', 'monster2', 'monster3', 'monster4', 'monster5',
        'outlaw', 'rcbandito', 'zhaba', 'vagrant', 'mammatus',
        'duster', 'hydra', 'lazer',
    },
}

Config.Effects = {
    shake = { type = 'LARGE_EXPLOSION_SHAKE', intensity = 1.5, duration = 1500 },
    armorLoss = 50,
    notifyDuration = 25000,
    sound = { enabled = true, event = 'InteractSound_CL:PlayOnOne', name = 'robberysound', volume = 0.5 },
}

Config.Damage = {
    engineHealthAfterFlip = 0.0,
    lockDuration = 8000,
    preventVisualDamage = true,
    autoRepairOnUpright = false,
}

Config.Fire = {
    enabled = true,
    chance = 5,
    delay = 5000,
    target = 'vehicle',
}

Config.Repair = {
    engineHealth = 800.0,
    bodyHealthBonus = 50.0,
    bodyHealthMax = 1000.0,
    liftOffset = 0.5,
}

Config.ForceFlip = {
    steps = 30,
    stepDelay = 5,
    targetPitch = 180.0,
}

Config.UI = {
    position = 'top-left',
    width = 360,
    radius = 14,
    maxVisible = 4,
    defaultDuration = 5000,
    font = "'Segoe UI', Roboto, Arial, sans-serif",
    colors = {
        background = 'rgba(12, 14, 20, 0.78)',
        highlight = 'rgba(255, 255, 255, 0.10)',
        border = 'rgba(255, 255, 255, 0.14)',
        text = '#f4f6fa',
        subtext = 'rgba(244, 246, 250, 0.72)',
        error = '#ff4d5e',
        warning = '#ffb020',
        info = '#4da3ff',
        success = '#34d399',
    },
}
