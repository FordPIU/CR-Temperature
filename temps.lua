local Temperature = 0
local Temperature_Offset = 0.0

local function getCurrentTime()
    return { GetClockHours(), GetClockMinutes() }
end

local retMonth = nil
RegisterNetEvent("retWorldMonth", function(month)
    retMonth = month
end)
local function getCurrentMonth()
    TriggerServerEvent("getWorldMonth")

    repeat
        Wait(0)
    until retMonth ~= nil

    local month = retMonth
    retMonth = nil

    return month
end

local function getCurrentWeather()
    return GetPrevWeatherTypeHashName()
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function RoundToDecimal(number, decimalPlaces)
    local multiplier = 10 ^ decimalPlaces
    return math.floor(number * multiplier + 0.5) / multiplier
end

local function CalculateTemperature(time, month, weather)
    local temperatureRanges = {
        [1] = { -15, 23 }, -- January
        [2] = { -10, 50 }, -- February
        [3] = { -5, 60 },  -- March
        [4] = { 0, 68 },   -- April
        [5] = { 5, 77 },   -- May
        [6] = { 68, 95 },  -- June (increased range for warm days)
        [7] = { 75, 95 },  -- July (increased range for warm days)
        [8] = { 68, 90 },  -- August (increased range for warm days)
        [9] = { 5, 77 },   -- September
        [10] = { 0, 68 },  -- October
        [11] = { -5, 59 }, -- November
        [12] = { -10, 50 } -- December
    }

    local weatherModifiers = {
        [`BLIZZARD`] = -45,  -- Very cold during snowstorm
        [`CLEAR`] = 18,      -- Warmer on clear days
        [`CLEARING`] = 10,   -- Warms up after rain/snow
        [`CLOUDS`] = 5,      -- Slightly warmer on cloudy days
        [`EXTRASUNNY`] = 36, -- Hot on extra sunny days
        [`FOGGY`] = -9,      -- Slightly cooler on foggy days
        [`HALLOWEEN`] = -9,  -- Slightly cooler on Halloween
        [`NEUTRAL`] = 0,     -- No significant change
        [`OVERCAST`] = -4,   -- Slightly cooler when overcast
        [`RAIN`] = -18,      -- Cooler during rain
        [`SMOG`] = -9,       -- Cooler in smog
        [`SNOW`] = -36,      -- Cold during snowfall
        [`SNOWLIGHT`] = -18, -- Cooler during light snow
        [`THUNDER`] = -9,    -- Cooler during thunderstorms
        [`XMAS`] = -9        -- Slightly cooler on Christmas
    }

    local timeDecimal = time[1] + time[2] / 60

    if timeDecimal >= 23.98 then
        timeDecimal = 0.0
    end

    local baseTemperature = 0
    if timeDecimal < 12 then
        baseTemperature = Lerp(temperatureRanges[month][1], temperatureRanges[month][2], timeDecimal / 12)
    else
        baseTemperature = Lerp(temperatureRanges[month][2], temperatureRanges[month][1], (timeDecimal - 12) / 12)
    end

    local weatherModifier = weatherModifiers[weather] or 0
    local temperature = baseTemperature + weatherModifier + Temperature_Offset

    Temperature_Offset = Temperature_Offset + GetRandomFloatInRange(-0.5, 0.5)

    return RoundToDecimal(temperature, 1)
end

local function TemperatureToRGB(temperature)
    local minTemp = 25
    local maxTemp = 100

    -- Ensure the temperature is within the valid range
    temperature = math.min(maxTemp, math.max(minTemp, temperature))

    -- Calculate the lerp factor for blue to red (0 to 1)
    local lerpFactor = (temperature - minTemp) / (maxTemp - minTemp)

    -- Lerp between a colder blue (60, 90, 255) and a warmer red (255, 60, 60)
    local r = math.floor(lerpFactor * 255 + (1 - lerpFactor) * 60)
    local g = 90
    local b = math.floor(lerpFactor * 60 + (1 - lerpFactor) * 255)

    return { r, g, b }
end

local function GetTextForTemperature(temperature)
    if temperature > 84 then
        return " - Heat Advisory"
    end
    if temperature < 33 then
        return " - Cold Advisory"
    end
end

local function DrawTemp(temp)
    local rgb = TemperatureToRGB(temp)
    local tempText = GetTextForTemperature(temp)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(rgb[1], rgb[2], rgb[3], 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(tostring(temp) .. "F" .. tempText)
    DrawText(0.25, 0.8)
end

function UpdateTemperature()
    Temperature = CalculateTemperature(getCurrentTime(), getCurrentMonth(), getCurrentWeather())
end

exports("GetTemperature", function()
    return Temperature
end)

Citizen.CreateThread(function()
    while true do
        UpdateTemperature()
        Wait(10000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        DrawTemp(Temperature)
    end
end)
