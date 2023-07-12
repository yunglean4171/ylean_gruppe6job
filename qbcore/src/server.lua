local QBCore = nil
QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("ylean_receive_salary")
AddEventHandler("ylean_receive_salary", function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    
    xPlayer.Functions.AddMoney(tostring(Ylean.Salary.type), tonumber(Ylean.Salary.amount))
end)