local QBCore = exports['qb-core']:GetCoreObject()
local isAdminPanelOpen = false

-- Admin panel commands
RegisterCommand('marketpanel', function()
    local PlayerData = QBCore.Functions.GetPlayerData()

    OpenAdminPanel()
end)

-- MARKET SATIN ALMA NPC SPAWN
local marketPurchaseNPC = nil
local marketPurchaseBlip = nil

CreateThread(function()
    local model = "s_m_m_migrant_01"
    local hash = GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local coords = vector4(-540.68, -195.44, 38.22, 297.19)
    marketPurchaseNPC = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(marketPurchaseNPC, true)
    SetEntityInvincible(marketPurchaseNPC, true)
    SetBlockingOfNonTemporaryEvents(marketPurchaseNPC, true)

    exports['qb-target']:AddTargetEntity(marketPurchaseNPC, {
        options = {
            {
                type = "client",
                event = "qg_markets:client:openMarketPurchase",
                icon = "fas fa-store",
                label = "Market Satın Al"
            }
        },
        distance = 2.5
    })

    print('[QG Markets] Market Purchase NPC spawned at ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
end)

-- Open market purchase panel
RegisterNetEvent('qg_markets:client:openMarketPurchase', function()
    OpenAdminPanel()
end)

-- Open admin management panel (market purchase panel)
function OpenAdminPanel()
    if isAdminPanelOpen then
        print('[QG Markets] Admin panel is already open, skipping...')
        return
    end

    print('[QG Markets] Opening admin panel...')
    isAdminPanelOpen = true

    QBCore.Functions.TriggerCallback('qg_markets:getMarketData', function(marketData)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAdminPanel',
            marketData = marketData,
            language = Config.Language
        })
        print('[QG Markets] Admin panel opened successfully')
    end)
end

-- Close admin panel
function CloseAdminPanel()
    print('[QG Markets] Closing admin panel...')
    isAdminPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeAdminPanel'
    })
    print('[QG Markets] Admin panel closed')
end

-- NUI Callbacks
RegisterNUICallback('closeAdminPanel', function(data, cb)
    CloseAdminPanel()
    cb('ok')
end)

RegisterNUICallback('purchaseMarket', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:purchaseMarket', function(success, message, newData)
        if success then
            QBCore.Functions.Notify(message or 'Market başarıyla satın alındı!', 'success', 3000)
            cb({ success = true, marketData = newData })

            print('[QG Markets Admin] Market purchased, triggering cache update...')
            TriggerEvent('qg_markets:client:updateOwnedMarkets')

            -- Close admin panel before opening management
            isAdminPanelOpen = false

            -- Open market management panel after purchase
            Wait(500)
            OpenMarketManagement(data.marketId, data.locationIndex)
        else
            QBCore.Functions.Notify(message or 'Market satın alınamadı!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.paymentMethod)
end)

RegisterNUICallback('sellMarket', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:sellMarket', function(success, message, newData)
        if success then
            QBCore.Functions.Notify(message or 'Market başarıyla satıldı!', 'success', 3000)
            cb({ success = true, marketData = newData })

            print('[QG Markets Admin] Market sold, triggering cache update...')
            -- Trigger the update event
            TriggerEvent('qg_markets:client:updateOwnedMarkets')
        else
            QBCore.Functions.Notify(message or 'Market satılamadı!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex)
end)

-- Escape key handler
RegisterCommand('+closeAdminPanel', function()
    if isAdminPanelOpen then
        CloseAdminPanel()
    end
end)

RegisterCommand('-closeAdminPanel', function() end)

RegisterKeyMapping('+closeAdminPanel', 'Close Admin Panel', 'keyboard', 'ESCAPE')

-- Market Management Functions
function OpenMarketManagement(marketId, locationIndex)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMarketManagement',
        marketId = marketId,
        locationIndex = locationIndex
    })
end

function CloseMarketManagement()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMarketManagement'
    })
end

-- Market management menu callbacks
RegisterNUICallback('closeMarketManagement', function(data, cb)
    CloseMarketManagement()
    cb('ok')
end)

RegisterNUICallback('openOwnedMarket', function(data, cb)
    OpenMarketManagement(data.marketId, data.locationIndex)
    cb('ok')
end)

-- Stock management callbacks
RegisterNUICallback('getMarketStock', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:getMarketStock', function(stock, error)
        if error then
            QBCore.Functions.Notify(error, 'error', 3000)
            cb({ success = false, stock = {} })
        else
            cb({ success = true, stock = stock or {} })
        end
    end, data.marketId, data.locationIndex)
end)

RegisterNUICallback('addStockToMarket', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:addStockToMarket', function(success, message, stock)
        if success then
            QBCore.Functions.Notify(message or 'Stok başarıyla eklendi!', 'success', 3000)
            cb({ success = true, stock = stock or {} })
        else
            QBCore.Functions.Notify(message or 'Stok eklenemedi!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.itemName, data.quantity)
end)

RegisterNUICallback('removeStockFromMarket', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:removeStockFromMarket', function(success, message, stock)
        if success then
            QBCore.Functions.Notify(message or 'Stok başarıyla çıkarıldı!', 'success', 3000)
            cb({ success = true, stock = stock or {} })
        else
            QBCore.Functions.Notify(message or 'Stok çıkarılamadı!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.itemName, data.quantity)
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:getPlayerInventory', function(inventory)
        cb({ success = true, inventory = inventory or {} })
    end)
end)

RegisterNUICallback('updateItemPrice', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:updateItemPrice', function(success, message, stock)
        if success then
            QBCore.Functions.Notify(message or 'Fiyat güncellendi!', 'success', 3000)
            cb({ success = true, stock = stock or {} })
        else
            QBCore.Functions.Notify(message or 'Fiyat güncellenemedi!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.itemName, data.price)
end)

RegisterNUICallback('getMarketSales', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:getMarketSales', function(salesData, error)
        if error then
            QBCore.Functions.Notify(error, 'error', 3000)
            cb({ success = false })
        else
            cb({ success = true, salesData = salesData or {} })
        end
    end, data.marketId, data.locationIndex)
end)

RegisterNUICallback('collectRevenue', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:collectRevenue', function(success, message, amount, salesData)
        if success then
            QBCore.Functions.Notify(message or 'Gelir toplandı!', 'success', 3000)
            cb({ success = true, amount = amount, salesData = salesData or {} })
        else
            QBCore.Functions.Notify(message or 'Gelir toplanamadı!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex)
end)

-- Employee management callbacks
RegisterNUICallback('getMarketEmployees', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:getMarketEmployees', function(employees, error)
        if error then
            QBCore.Functions.Notify(error, 'error', 3000)
            cb({ success = false, employees = {} })
        else
            cb({ success = true, employees = employees or {} })
        end
    end, data.marketId, data.locationIndex)
end)

RegisterNUICallback('addEmployee', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:addEmployee', function(success, message, employees)
        if success then
            QBCore.Functions.Notify(message or 'Çalışan eklendi!', 'success', 3000)
            cb({ success = true, employees = employees or {} })
        else
            QBCore.Functions.Notify(message or 'Çalışan eklenemedi!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.targetCitizenId)
end)

RegisterNUICallback('removeEmployee', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:removeEmployee', function(success, message, employees)
        if success then
            QBCore.Functions.Notify(message or 'Çalışan çıkarıldı!', 'success', 3000)
            cb({ success = true, employees = employees or {} })
        else
            QBCore.Functions.Notify(message or 'Çalışan çıkarılamadı!', 'error', 3000)
            cb({ success = false })
        end
    end, data.marketId, data.locationIndex, data.targetCitizenId)
end)

RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = {}

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)

        if player ~= PlayerId() and distance < 5.0 then
            local serverId = GetPlayerServerId(player)
            local playerName = GetPlayerName(player)

            table.insert(nearbyPlayers, {
                serverId = serverId,
                name = playerName,
                distance = distance
            })
        end
    end

    -- Sort by distance
    table.sort(nearbyPlayers, function(a, b)
        return a.distance < b.distance
    end)

    cb({ success = true, players = nearbyPlayers })
end)

RegisterNUICallback('addEmployeeByServerId', function(data, cb)
    QBCore.Functions.TriggerCallback('qg_markets:addEmployeeByServerId', function(success, message, employees)
        if success then
            QBCore.Functions.Notify(message or 'Çalışan eklendi!', 'success', 3000)
            cb({ success = true, employees = employees or {} })
        else
            QBCore.Functions.Notify(message or 'Çalışan eklenemedi!', 'error', 3000)
            cb({ success = false, message = message })
        end
    end, data.marketId, data.locationIndex, data.targetServerId)
end)
