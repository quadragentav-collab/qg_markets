local QBCore = exports['qb-core']:GetCoreObject()
local isMarketOpen = false
local isVendingOpen = false
local currentMarket = nil
local currentVending = nil
local spawnedPeds = {}
local spawnedVendingMachines = {}
local pedGreetings = {}
local playerOwnedMarkets = {} -- Cache for player's owned markets

-- Market NPC spawn thread
CreateThread(function()
    for marketId, market in pairs(Config.Markets) do
        local model = market.pedModel or "mp_m_shopkeep_01"
        local hash = GetHashKey(model)

        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end

        for locationIndex, location in pairs(market.locations) do
            local coords = location.coords
            local heading = location.heading or 0.0

            local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, heading, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)

            table.insert(spawnedPeds, {ped = ped, marketId = marketId, locationIndex = locationIndex})

            -- Store marketId and locationIndex for later use
            local mId = marketId
            local lIndex = locationIndex

            local targetOptions = {
                {
                    type = "client",
                    event = "qg_markets:client:openMarket",
                    icon = "fas fa-store",
                    label = market.TargetLabel,
                    marketId = mId,
                    locationIndex = lIndex,
                    pedEntity = ped
                },
                {
                    type = "client",
                    event = "qg_markets:client:openMarketManagement",
                    icon = "fas fa-cog",
                    label = "Marketi Yönet",
                    marketId = mId,
                    locationIndex = lIndex,
                    canInteract = function()
                        local key = mId .. "_" .. lIndex
                        local isOwner = playerOwnedMarkets[key] == true
                        print('[QG Markets] canInteract check - Market: ' .. mId .. ', Location: ' .. lIndex .. ', IsOwner: ' .. tostring(isOwner))
                        return isOwner
                    end
                }
            }

            if Config.GreetingSystem.enabled and market.GreetingLabel then
                table.insert(targetOptions, {
                    type = "client",
                    event = "qg_markets:client:greetPed",
                    icon = "fas fa-hand-paper",
                    label = market.GreetingLabel,
                    marketId = mId,
                    pedEntity = ped
                })
            end

            exports['qb-target']:AddTargetEntity(ped, {
                options = targetOptions,
                distance = 2.5
            })

            print('[QG Markets] Spawned NPC for market ' .. mId .. ' location ' .. lIndex)
        end
    end
end)

-- Vending Machine detection and target setup
CreateThread(function()
    Wait(2000) -- Wait for world to load
    
    for vendingId, vendingData in pairs(Config.VendingMachines) do
        for _, modelHash in pairs(vendingData.model) do
            exports['qb-target']:AddTargetModel(modelHash, {
                options = {
                    {
                        type = "client",
                        event = "qg_markets:client:openVending",
                        icon = "fas fa-shopping-cart",
                        label = vendingData.targetLabel,
                        vendingId = vendingId
                    }
                },
                distance = 2.5
            })
        end
    end
end)

-- 3D Text Drawing Function
function DrawText3D(x, y, z, text, scale, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    
    if onScreen then
        local scale = (1 / dist) * scale
        local fov = (1 / GetGameplayCamFov()) * 100
        local factor = scale * fov
        
        SetTextScale(0.0 * factor, 1.15 * factor)
        SetTextFont(11)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Greeting display thread
CreateThread(function()
    while true do
        Wait(0)
        
        if Config.GreetingSystem.enabled then
            for pedEntity, greetingData in pairs(pedGreetings) do
                if DoesEntityExist(pedEntity) then
                    local pedCoords = GetEntityCoords(pedEntity)
                    local textCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + Config.GreetingSystem.textHeight)
                    
                    if GetGameTimer() - greetingData.startTime <= Config.GreetingSystem.displayTime then
                        DrawText3D(textCoords.x, textCoords.y, textCoords.z, greetingData.text, Config.GreetingSystem.textScale, Config.GreetingSystem.textColor)
                    else
                        pedGreetings[pedEntity] = nil
                    end
                else
                    pedGreetings[pedEntity] = nil
                end
            end
        end
        
        if next(pedGreetings) == nil then
            Wait(1000)
        end
    end
end)

-- Greeting event
RegisterNetEvent("qg_markets:client:greetPed", function(data)
    local marketId = data.marketId
    local pedEntity = data.pedEntity
    
    if marketId and pedEntity and DoesEntityExist(pedEntity) then
        local market = Config.Markets[marketId]
        
        if market and market.GreetingResponse then
            pedGreetings[pedEntity] = {
                text = market.GreetingResponse,
                startTime = GetGameTimer()
            }
            
            TaskStartScenarioInPlace(pedEntity, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
            Wait(3000)
            ClearPedTasksImmediately(pedEntity)
        end
    end
end)

-- Market open event
RegisterNetEvent("qg_markets:client:openMarket", function(data)
    local marketId = data.marketId
    local pedEntity = data.pedEntity
    local locationIndex = data.locationIndex

    if marketId then
        print("Market açılıyor:", marketId)

        if pedEntity and DoesEntityExist(pedEntity) then
            local market = Config.Markets[marketId]
            if market and market.TargetResponse then
                pedGreetings[pedEntity] = {
                    text = market.TargetResponse,
                    startTime = GetGameTimer()
                }
            end
        end

        OpenMarket(marketId, locationIndex)
    else
        print("Market ID bulunamadı.")
    end
end)

-- Market management event
RegisterNetEvent("qg_markets:client:openMarketManagement", function(data)
    local marketId = data.marketId
    local locationIndex = data.locationIndex

    if marketId and locationIndex then
        print("Market yönetimi açılıyor:", marketId, locationIndex)
        OpenMarketManagementFromNPC(marketId, locationIndex)
    end
end)

-- Vending machine open event
RegisterNetEvent("qg_markets:client:openVending", function(data)
    local vendingId = data.vendingId
    
    if vendingId then
        OpenVending(vendingId)
    else
    end
end)

-- WeaponLicense check function
function CheckWeaponLicense()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return false end
    
    if GetResourceState('ox_inventory') == 'started' then
        local hasLicense = exports.ox_inventory:Search('count', 'weaponlicense')
        return hasLicense and hasLicense > 0
    else
        for _, item in pairs(Player.items) do
            if item.name == 'weaponlicense' and item.amount > 0 then
                return true
            end
        end
    end
    
    return false
end

-- Market Functions
-- Helper function to get item label from ox_inventory
local function GetItemLabel(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local item = exports.ox_inventory:Items(itemName)
        if item then
            return item.label
        end
    end
    return nil
end

function OpenMarket(marketId, locationIndex)
    print("Market açılıyor:", marketId, locationIndex)
    if isMarketOpen or isVendingOpen then return end

    currentMarket = marketId
    isMarketOpen = true

    local hasLicense = true
    local market = Config.Markets[marketId]

    if market.requiresLicense then
        hasLicense = CheckWeaponLicense()
        if not hasLicense then
            exports['ox_lib']:notify({
                title = 'Market',
                description = Config.Language['no_weapon_license'],
                type = 'error'
            })
        end
    end

    -- Get stock from server if location provided
    if locationIndex then
        QBCore.Functions.TriggerCallback('qg_markets:getMarketStockForPurchase', function(stock, hasStock, itemImages)
            local marketData = {}

            -- Deep copy market data (excluding items)
            for k, v in pairs(market) do
                if k ~= 'items' then
                    if type(v) == 'table' then
                        marketData[k] = {}
                        for k2, v2 in pairs(v) do
                            marketData[k][k2] = v2
                        end
                    else
                        marketData[k] = v
                    end
                end
            end

            -- CRITICAL: Handle different market states
            -- hasStock = false: Market has NO owner -> use config default items
            -- hasStock = true, stock = {}: Market has owner but NO stock -> empty market
            -- hasStock = true, stock = [...]: Market has owner with stock -> show stock
            if hasStock then
                -- Market has an owner
                if stock and #stock > 0 then
                    -- Owner has stock, show it
                    marketData.items = stock
                    if itemImages then
                        for i, item in ipairs(marketData.items) do
                            if itemImages[item.name] then
                                marketData.items[i].image = itemImages[item.name]
                            end
                        end
                    end
                else
                    -- Owner exists but no stock = empty market
                    marketData.items = {}
                end
            else
                -- No owner, use config default items
                marketData.items = {}
                if market.items then
                    for i, item in ipairs(market.items) do
                        marketData.items[i] = {}
                        for k, v in pairs(item) do
                            marketData.items[i][k] = v
                        end
                        -- Try to get label from ox_inventory
                        local oxLabel = GetItemLabel(item.name)
                        if oxLabel then
                            marketData.items[i].label = oxLabel
                        end
                    end
                end
            end

            marketData.locationIndex = locationIndex

            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openMarket',
                marketData = marketData,
                language = Config.Language,
                paymentMethods = Config.PaymentMethods,
                hasLicense = hasLicense,
                hasCustomStock = hasStock  -- true if market has owner, false if no owner
            })
        end, marketId, locationIndex)
    else
        -- Update item labels from ox_inventory for default market items
        local marketData = {}
        for k, v in pairs(market) do
            if type(v) == 'table' and k ~= 'items' then
                marketData[k] = {}
                for k2, v2 in pairs(v) do
                    marketData[k][k2] = v2
                end
            elseif k ~= 'items' then
                marketData[k] = v
            end
        end

        -- Deep copy items and update labels
        marketData.items = {}
        if market.items then
            for i, item in ipairs(market.items) do
                marketData.items[i] = {}
                for k, v in pairs(item) do
                    marketData.items[i][k] = v
                end
                -- Try to get label from ox_inventory
                local oxLabel = GetItemLabel(item.name)
                if oxLabel then
                    marketData.items[i].label = oxLabel
                end
            end
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openMarket',
            marketData = marketData,
            language = Config.Language,
            paymentMethods = Config.PaymentMethods,
            hasLicense = hasLicense,
            hasCustomStock = false
        })
    end
end

-- Vending Machine Functions
function OpenVending(vendingId)
    if isMarketOpen or isVendingOpen then return end
    
    currentVending = vendingId
    isVendingOpen = true
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openVending',
        vendingData = Config.VendingMachines[vendingId],
        language = Config.Language,
        paymentMethods = Config.PaymentMethods
    })
end

function CloseMarket()
    isMarketOpen = false
    currentMarket = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMarket'
    })
end

function CloseVending()
    isVendingOpen = false
    currentVending = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeVending'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeMarket', function(data, cb)
    CloseMarket()
    cb('ok')
end)

RegisterNUICallback('closeVending', function(data, cb)
    CloseVending()
    cb('ok')
end)

RegisterNUICallback('showNotification', function(data, cb)
    local message = data.message or 'Bildirim'
    local notifyType = data.type or 'primary'
    
    QBCore.Functions.Notify(message, notifyType, 3000)
    
    cb('ok')
end)

RegisterNUICallback('purchaseItems', function(data, cb)
    local paymentMethod = data.paymentMethod
    local items = data.items
    local total = data.total
    local purchaseType = data.purchaseType or 'market'
    local locationIndex = data.locationIndex

    if not paymentMethod or not items or not total then
        exports['ox_lib']:notify({
            title = 'Market',
            description = Config.Language['purchase_failed'],
            type = 'error'
        })
        cb({ success = false, message = Config.Language['purchase_failed'] })
        return
    end

    QBCore.Functions.TriggerCallback('qg_markets:purchaseItems', function(success, message)
        if success then
            exports['ox_lib']:notify({
                title = 'Market',
                description = message or Config.Language['purchase_successful'],
                type = 'success'
            })
        else
            exports['ox_lib']:notify({
                title = 'Market',
                description = message or Config.Language['purchase_failed'],
                type = 'error'
            })
        end

        cb({ success = success, message = message })

        if success then
            Wait(1000)
            if purchaseType == 'vending' then
                CloseVending()
            else
                CloseMarket()
            end
        end
    end, {
        paymentMethod = paymentMethod,
        items = items,
        total = total,
        marketId = currentMarket,
        vendingId = currentVending,
        purchaseType = purchaseType,
        locationIndex = locationIndex
    })
end)

-- Key Handler
RegisterCommand('+closeMarket', function()
    if isMarketOpen then
        CloseMarket()
    elseif isVendingOpen then
        CloseVending()
    end
end)

RegisterCommand('-closeMarket', function() end)

RegisterKeyMapping('+closeMarket', 'Close Market/Vending', 'keyboard', 'ESCAPE')

-- Cleanup thread
CreateThread(function()
    while true do
        Wait(30000)

        for pedEntity, _ in pairs(pedGreetings) do
            if not DoesEntityExist(pedEntity) then
                pedGreetings[pedEntity] = nil
            end
        end
    end
end)

-- Check if player owns a market
function IsPlayerOwnerOfMarket(marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return false end

    local key = marketId .. "_" .. locationIndex
    return playerOwnedMarkets[key] == true
end

-- Update owned markets cache
function UpdateOwnedMarketsCache()
    print('[QG Markets] Updating owned markets cache...')
    QBCore.Functions.TriggerCallback('qg_markets:getPlayerOwnedMarkets', function(ownedMarkets)
        -- Clear old cache first
        for k in pairs(playerOwnedMarkets) do
            playerOwnedMarkets[k] = nil
        end

        print('[QG Markets] Received owned markets count: ' .. #ownedMarkets)
        for _, market in pairs(ownedMarkets) do
            local key = market.marketId .. "_" .. market.locationIndex
            playerOwnedMarkets[key] = true
            print('[QG Markets] Player owns: ' .. key)
        end

        -- Force qb-target to refresh (this helps update canInteract)
        print('[QG Markets] Cache updated, total owned: ' .. TableLength(playerOwnedMarkets))
    end)
end

-- Helper function to count table entries
function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Open market management from NPC
function OpenMarketManagementFromNPC(marketId, locationIndex)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMarketManagement',
        marketId = marketId,
        locationIndex = locationIndex
    })
end

-- Update cache on resource start and periodically
CreateThread(function()
    Wait(2000)
    UpdateOwnedMarketsCache()

    while true do
        Wait(60000) -- Update every minute
        UpdateOwnedMarketsCache()
    end
end)

-- Update cache when market is purchased/sold
RegisterNetEvent('qg_markets:client:updateOwnedMarkets', function()
    print('[QG Markets] Received updateOwnedMarkets event')
    UpdateOwnedMarketsCache()
end)

-- Debug command to check owned markets
RegisterCommand('checkownedmarkets', function()
    print('[QG Markets] === Player Owned Markets Cache ===')
    local count = 0
    for key, value in pairs(playerOwnedMarkets) do
        print('[QG Markets] ' .. key .. ' = ' .. tostring(value))
        count = count + 1
    end
    print('[QG Markets] Total: ' .. count)
    print('[QG Markets] Requesting fresh data from server...')
    UpdateOwnedMarketsCache()
end, false)

-- WHOLESALER NPC SPAWN AND INTERACTION
CreateThread(function()
    local model = Config.Wholesaler.pedModel
    local hash = GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local coords = Config.Wholesaler.location
    local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "qg_markets:client:openWholesaler",
                icon = "fas fa-box",
                label = Config.Wholesaler.targetLabel,
                canInteract = function()
                    for key, isOwner in pairs(playerOwnedMarkets) do
                        if isOwner then
                            return true
                        end
                    end
                    return false
                end
            }
        },
        distance = 2.5
    })

    print('[QG Markets] Wholesaler NPC spawned at ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
end)

-- Wholesaler blip (only for market owners)
CreateThread(function()
    Wait(5000)

    local function UpdateWholesalerBlip()
        local hasMarket = false
        for key, isOwner in pairs(playerOwnedMarkets) do
            if isOwner then
                hasMarket = true
                break
            end
        end

        if hasMarket and not wholesalerBlip then
            local coords = Config.Wholesaler.location
            wholesalerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(wholesalerBlip, Config.Wholesaler.blip.sprite)
            SetBlipDisplay(wholesalerBlip, Config.Wholesaler.blip.display)
            SetBlipScale(wholesalerBlip, Config.Wholesaler.blip.scale)
            SetBlipColour(wholesalerBlip, Config.Wholesaler.blip.color)
            SetBlipAsShortRange(wholesalerBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Toptancı")
            EndTextCommandSetBlipName(wholesalerBlip)
            print('[QG Markets] Wholesaler blip created')
        elseif not hasMarket and wholesalerBlip then
            RemoveBlip(wholesalerBlip)
            wholesalerBlip = nil
            print('[QG Markets] Wholesaler blip removed')
        end
    end

    while true do
        Wait(60000)
        UpdateWholesalerBlip()
    end
end)

local wholesalerBlip = nil

-- Open wholesaler interface
RegisterNetEvent('qg_markets:client:openWholesaler', function()
    QBCore.Functions.TriggerCallback('qg_markets:getPlayerOwnedMarkets', function(ownedMarkets)
        if #ownedMarkets == 0 then
            exports['ox_lib']:notify({
                title = 'Toptancı',
                description = 'Bir marketiniz yok!',
                type = 'error'
            })
            return
        end

        QBCore.Functions.TriggerCallback('qg_markets:getPlayerOrders', function(orders)
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openWholesaler',
                products = Config.Wholesaler.products,
                ownedMarkets = ownedMarkets,
                orders = orders,
                config = {
                    expressMultiplier = Config.Wholesaler.expressDeliveryMultiplier,
                    baseDeliveryTime = Config.Wholesaler.baseDeliveryTime
                }
            })
        end)
    end)
end)

-- Close wholesaler
RegisterNUICallback('closeWholesaler', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Place wholesaler order
RegisterNUICallback('placeWholesalerOrder', function(data, cb)
    local marketId = data.marketId
    local locationIndex = data.locationIndex
    local items = data.items
    local expressDelivery = data.expressDelivery or false
    local paymentMethod = data.paymentMethod or 'bank'

    QBCore.Functions.TriggerCallback('qg_markets:placeWholesalerOrder', function(success, message, order)
        if success then
            exports['ox_lib']:notify({
                title = 'Toptancı',
                description = message,
                type = 'success'
            })
        else
            exports['ox_lib']:notify({
                title = 'Toptancı',
                description = message,
                type = 'error'
            })
        end

        cb({ success = success, message = message, order = order })
    end, marketId, locationIndex, items, expressDelivery, paymentMethod)
end)

-- Collect wholesaler order
RegisterNUICallback('collectWholesalerOrder', function(data, cb)
    local orderId = data.orderId

    QBCore.Functions.TriggerCallback('qg_markets:collectWholesalerOrder', function(success, message)
        if success then
            exports['ox_lib']:notify({
                title = 'Toptancı',
                description = message,
                type = 'success'
            })
        else
            exports['ox_lib']:notify({
                title = 'Toptancı',
                description = message,
                type = 'error'
            })
        end

        cb({ success = success, message = message })
    end, orderId)
end)