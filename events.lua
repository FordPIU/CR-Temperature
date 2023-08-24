RegisterNetEvent("getWorldMonth", function()
    TriggerClientEvent("retWorldMonth", source, os.date('*t', os.time()).month)
end)

local Temperature_Offset = 0.0

local function getRandomFloatInRange(minRange, maxRange)
    return minRange + math.random() * (maxRange - minRange)
end

Citizen.CreateThread(function()
    while true do
        Wait(60000)

        Temperature_Offset = Temperature_Offset + getRandomFloatInRange(-0.1, 0.1)

        TriggerClientEvent("sendTemperatureOffset", -1, Temperature_Offset)
    end
end)
