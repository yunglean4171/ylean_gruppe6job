ESX = exports["es_extended"]:getSharedObject()

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("ylean_receive_salary")
AddEventHandler("ylean_receive_salary", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.addAccountMoney(tostring(Ylean.Salary.type), tonumber(Ylean.Salary.amount))
end)
