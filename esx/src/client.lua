ESX = exports['es_extended']:getSharedObject()

local PlayerData = nil

local vehicle_returned = true
local blips = {}
local armored_vehicle
local is_carrying_cash = false
local object
local completed_points = 0
local job_guy
local main_blip

Citizen.CreateThread(function()
	while ESX == nil do
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
    if PlayerData.job.name == Ylean.JobName and job_guy == nil and main_blip == nil then
        Citizen.CreateThread(function()
            main_blip = AddBlipForCoord(Ylean.Config.job_guy_coords.xyz)
            SetBlipAsShortRange(blip, true)
            SetBlipSprite(blip, 67)
            SetBlipScale(blip, 1.0)
            SetBlipColour(blip, 1)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Ylean.Locales.main_blip_name)
            EndTextCommandSetBlipName(blip)
        end)

        job_guy = createPed()

        exports.ox_target:addLocalEntity(job_guy,
            {
                {
                    name = "startJob",
                    event = "ylean_start_job",
                    icon = "fas fa-sign-in-alt",
                    label = Ylean.Locales.start_job_label,
                    distance = 2.5
                },
                {
                    name = "endJob",
                    event = "ylean_end_job",
                    icon = "fas fa-car",
                    label = Ylean.Locales.end_job_label,
                    distance = 2.5

                }
            })
    end
end)

function createPed()
    local pedModel = GetHashKey(Ylean.Config.job_guy_model)
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(0)
    end
    
    local ped = CreatePed(4, pedModel, Ylean.Config.job_guy_coords.xyz, Ylean.Config.job_guy_coords.w, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Pobierz animacje
    local animDict = "amb@world_human_clipboard@male@idle_a"
    local animName = "idle_a"

    -- Załaduj animacje
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

    -- Dodaj obiekt notesu do ręki peda
    local prop_name = "p_amb_clipboard_01"
    local prop_hash = GetHashKey(prop_name)
    
    RequestModel(prop_hash)
    while not HasModelLoaded(prop_hash) do
        Wait(0)
    end
    
    local prop = CreateObject(prop_hash, 1.0, 1.0, 1.0, true, true, false)

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 0x49D9), 0.16, 0.02, 0.06, -130.0, 350.0, 0.0, true, true, false, true, 1, true)
    
    -- Odtwórz animację
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    SetPedConfigFlag(ped, 251, true)
    return ped
end

function spawnVehicle()
    local vehicleModel = GetHashKey("stockade") -- Zamień na model pojazdu, który chcesz zespawnować

    -- Sprawdź, czy model pojazdu jest prawidłowy
    if not IsModelValid(vehicleModel) then
        print("invalid vehicle model")
        return
    end

    RequestModel(vehicleModel) -- Prośba o załadowanie modelu pojazdu

    while not HasModelLoaded(vehicleModel) do -- Czekaj, aż model pojazdu zostanie załadowany
        Wait(0)
    end

    -- Utwórz pojazd na określonych koordynatach
    local vehicle = CreateVehicle(vehicleModel, Ylean.Config.vehicle_coords.xyz, Ylean.Config.vehicle_coords.w, true, false)

    -- Upewnij się, że pojazd zostanie prawidłowo zainicjowany
    if not DoesEntityExist(vehicle) then
        print("vehicle error")
        return
    end

    -- Ustaw jako misję pojazdu, aby uniknąć jego zniknięcia
    SetEntityAsMissionEntity(vehicle, true, true)

    -- Zwolnij model pojazdu z pamięci
    SetModelAsNoLongerNeeded(vehicleModel)
    
    return vehicle
end

function createBlips()
    for i, point in ipairs(Ylean.DeliveryPoints) do
        local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)

        -- Ustawiamy właściwości blipu
        SetBlipSprite(blip, 457) -- Ustawiamy typ na 457
        SetBlipColour(blip, 2) -- Ustawiamy kolor na zielony (2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Ylean.Locales.delivery_blip_name) -- Ustawiamy nazwę blipu
        EndTextCommandSetBlipName(blip)
        
        table.insert(blips, blip) -- Dodajemy blip do listy
    end
end

function deleteNearestBlip()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Znajdź najbliższy blip
    local nearestBlipIndex = -1
    local nearestBlipDistance = math.huge -- Ustaw na początkowo nieskończoną odległość
    for i, blip in ipairs(blips) do
        local blipCoords = GetBlipCoords(blip)
        local distance = GetDistanceBetweenCoords(playerCoords, blipCoords, true)

        -- Jeżeli ten blip jest bliżej gracza, to zaktualizuj najbliższy blip
        if distance < nearestBlipDistance then
            nearestBlipIndex = i
            nearestBlipDistance = distance
        end
    end

    -- Usuń najbliższy blip
    if nearestBlipIndex ~= -1 then
        RemoveBlip(blips[nearestBlipIndex])
        table.remove(blips, nearestBlipIndex)
    end
end


function detachMoneyBagFromPlayer()
    if DoesEntityExist(object) then
        -- Odczepienie obiektu od gracza
        DetachEntity(object, true, false)

        -- Usunięcie obiektu
        DeleteEntity(object)
        object = nil
    end
end

function mark_point_as_delivered()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Znajdź najbliższy punkt dostawy
    local nearestPointIndex = -1
    local nearestPointDistance = math.huge -- Ustaw na początkowo nieskończoną odległość
    for i, point in ipairs(Ylean.DeliveryPoints) do
        local distance = GetDistanceBetweenCoords(playerCoords, point.coords, true)

        -- Jeżeli ten punkt jest bliżej gracza, to zaktualizuj najbliższy punkt
        if distance < nearestPointDistance then
            nearestPointIndex = i
            nearestPointDistance = distance
        end
    end

    -- Oznacz najbliższy punkt jako dostarczony
    if nearestPointIndex ~= -1 then
        Ylean.DeliveryPoints[nearestPointIndex].delivered = true
    end
end

function drawHint(text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5,0.8)
end

function IsJobGruppe6()
	if PlayerData ~= nil then
		local isJob = false
		if PlayerData.job.name ~= nil and PlayerData.job.name == Ylean.JobName then
			isJob = true
		end
		return isJob
	end
end

Citizen.CreateThread(function()
    while PlayerData == nil do
        Citizen.Wait(0)
    end

    if IsJobGruppe6() then
        Citizen.CreateThread(function()
            main_blip = AddBlipForCoord(Ylean.Config.job_guy_coords.xyz)
            SetBlipAsShortRange(blip, true)
            SetBlipSprite(blip, 67)
            SetBlipScale(blip, 1.0)
            SetBlipColour(blip, 1)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Ylean.Locales.main_blip_name)
            EndTextCommandSetBlipName(blip)
        end)

        job_guy = createPed()

        exports.ox_target:addLocalEntity(job_guy,
            {
                {
                    name = "startJob",
                    event = "ylean_start_job",
                    icon = "fas fa-sign-in-alt",
                    label = Ylean.Locales.start_job_label,
                    distance = 2.5
                },
                {
                    name = "endJob",
                    event = "ylean_end_job",
                    icon = "fas fa-car",
                    label = Ylean.Locales.end_job_label,
                    distance = 2.5

                }
            })
    end
end)

RegisterNetEvent("ylean_start_job")
AddEventHandler("ylean_start_job", function()
    if IsJobGruppe6() then
        if vehicle_returned then
            vehicle_returned = false

            armored_vehicle = spawnVehicle()

            exports.ox_target:addLocalEntity(armored_vehicle,
            {
                {
                    name = "repairVehicle",
                    event = "ylean_repair_vehicle",
                    icon = "fas fa-wrench",
                    label = Ylean.Locales.repair_vehicle_label,
                    distance = 2.5
                },
                {
                    name = "getCash",
                    event = "ylean_get_cash",
                    icon = "fas fa-suitcase",
                    label = Ylean.Locales.get_cash_label,
                    distance = 2.5
    
                }
            })
            createBlips()
        else
            TriggerEvent('esx:showNotification',Ylean.Locales.job_in_progress)
        end
    end
end)

RegisterNetEvent("ylean_repair_vehicle")
AddEventHandler("ylean_repair_vehicle", function()
    if not vehicle_returned then
        SetVehicleFixed(armored_vehicle)
        SetVehicleDirtLevel(armored_vehicle, 0.0)
    end
end)

RegisterNetEvent("ylean_get_cash")
AddEventHandler("ylean_get_cash", function()
    if is_carrying_cash  then
        TriggerEvent('esx:showNotification',Ylean.Locales.error)
    elseif not is_carrying_cash and not vehicle_returned and not (completed_points == #Ylean.DeliveryPoints) then
        is_carrying_cash = true
        local playerPed = PlayerPedId()
        local bagModel = GetHashKey("prop_ld_case_01") -- Model stalowej walizki
    
        RequestModel(bagModel)
        while not HasModelLoaded(bagModel) do
            Wait(0) -- czekaj na załadowanie modelu
        end
    
        -- Stworzenie obiektu
        local coords = GetEntityCoords(playerPed)
        object = CreateObject(bagModel, coords.x, coords.y, coords.z, true, true, true)
    
        -- Przyczepienie obiektu do gracza
        AttachEntityToEntity(object, playerPed, GetPedBoneIndex(playerPed, 57005), 0.15, 0.05, 0.0, 160.0, 100.0, 100.0, true, true, false, true, 1, true)
    
        -- Zwolnienie modelu
        SetModelAsNoLongerNeeded(bagModel)

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
        
                -- Znajdź najbliższy punkt dostawy
                local nearestPointIndex = -1
                local nearestPointDistance = math.huge -- Ustaw na początkowo nieskończoną odległość
                for i, point in ipairs(Ylean.DeliveryPoints) do
                    local distance = GetDistanceBetweenCoords(playerCoords, point.coords, true)
        
                    -- Jeżeli ten punkt jest bliżej gracza, to zaktualizuj najbliższy punkt
                    if distance < nearestPointDistance then
                        nearestPointIndex = i
                        nearestPointDistance = distance
                    end
                end
        
                -- Jeżeli gracz jest blisko punktu dostawy, wyświetl wskazówkę i umożliw dostarczenie pieniędzy
                if nearestPointIndex ~= -1 and nearestPointDistance < 1.5 and is_carrying_cash and not Ylean.DeliveryPoints[nearestPointIndex].delivered then
                    drawHint(Ylean.Locales.hint)
                    if IsControlJustReleased(0, 38) then
                        detachMoneyBagFromPlayer()
                        is_carrying_cash = false
                        deleteNearestBlip()
                        mark_point_as_delivered()

                        if completed_points == #Ylean.DeliveryPoints - 1 then
                            completed_points = completed_points + 1
                            TriggerEvent('esx:showNotification',Ylean.Locales.all_deliveries_completed)
                        else
                            completed_points = completed_points + 1
                            TriggerEvent('esx:showNotification',Ylean.Locales.deliveries_status..""..completed_points.."/"..#Ylean.DeliveryPoints)
                        end
                    end
                end
            end
        end)        
    end
end)

function resetDelivered()
    for i, point in ipairs(Ylean.DeliveryPoints) do
        point.delivered = false
    end
end

RegisterNetEvent("ylean_end_job")
AddEventHandler("ylean_end_job", function()
    if completed_points == #Ylean.DeliveryPoints then
        SetEntityAsMissionEntity(armored_vehicle, false, true) -- oznacza pojazd jako "mission entity"
        DeleteVehicle(armored_vehicle) -- usuwa pojazd
        vehicle_returned = true
        TriggerEvent('esx:showNotification',Ylean.Locales.salary_received..""..Ylean.Salary.amount)
        completed_points = 0
	    resetDelivered()
        TriggerServerEvent("ylean_receive_salary")
    else
        TriggerEvent('esx:showNotification', Ylean.Locales.error2)
    end
end)
