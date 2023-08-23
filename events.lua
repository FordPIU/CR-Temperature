RegisterNetEvent("getWorldMonth", function(month)
    TriggerClientEvent("retWorldMonth", source, os.date('*t', os.time()).month)
end)
