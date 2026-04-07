local QBCore = exports['qb-core']:GetCoreObject()

-- Ox_inventory item verilerini çek
local function GetOxItems()
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:Items()
    end
    return nil
end

-- Get item image from ox_inventory
local function GetItemImage(itemName)
    if GetResourceState('ox_inventory') == 'started' then
        local items = exports.ox_inventory:Items()
        if items and items[itemName] then
            return items[itemName].image or (itemName .. '.png')
        end
    end
    return itemName .. '.png'
end

-- WeaponLicense kontrol fonksiyonu (server-side)
local function CheckPlayerWeaponLicense(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Ox_inventory kontrolü
    if GetResourceState('ox_inventory') == 'started' then
        local hasLicense = exports.ox_inventory:Search(source, 'count', 'weaponlicense')
        return hasLicense and hasLicense > 0
    else
        -- QBCore inventory kontrolü
        local hasLicense = Player.Functions.GetItemByName('weaponlicense')
        return hasLicense and hasLicense.amount > 0
    end
end

-- Purchase Items Callback
QBCore.Functions.CreateCallback('qg_markets:purchaseItems', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        print('[QG Markets] Player not found: ' .. source)
        cb(false, Config.Language['purchase_failed'])
        return
    end
    
    local paymentMethod = data.paymentMethod
    local items = data.items
    local total = data.total
    local marketId = data.marketId
    local vendingId = data.vendingId
    local purchaseType = data.purchaseType or 'market'
    local locationIndex = data.locationIndex
    
    -- Validate data
    if not paymentMethod or not items or not total then
        print('[QG Markets] Invalid purchase data received')
        cb(false, Config.Language['purchase_failed'])
        return
    end
    
    -- Vending machine için ayrı kontrol
    if purchaseType == 'vending' and vendingId then
        print(string.format('[QG Markets] Vending purchase: %s', vendingId))
        -- Vending machine için lisans kontrolü gerekmez
    elseif marketId then
        -- Market satın alma için lisans kontrolü
        local market = Config.Markets[marketId]
        if market and market.requiresLicense then
            local hasLicense = CheckPlayerWeaponLicense(source)
            if not hasLicense then
                print('[QG Markets] Player does not have weapon license')
                cb(false, Config.Language['no_weapon_license'])
                return
            end
        end
    else
        print('[QG Markets] Neither marketId nor vendingId provided')
        cb(false, Config.Language['purchase_failed'])
        return
    end
    
    -- Check if player has enough money
    local playerMoney = 0
    if paymentMethod == 'cash' then
        playerMoney = Player.PlayerData.money.cash or 0
    elseif paymentMethod == 'bank' then
        playerMoney = Player.PlayerData.money.bank or 0
    else
        print('[QG Markets] Invalid payment method: ' .. tostring(paymentMethod))
        cb(false, Config.Language['purchase_failed'])
        return
    end
    
    print(string.format('[QG Markets] Player %s has $%d in %s, trying to spend $%d', 
        Player.PlayerData.citizenid, playerMoney, paymentMethod, total))
    
    if playerMoney < total then
        print('[QG Markets] Insufficient funds')
        cb(false, Config.Language['insufficient_funds'])
        return
    end
    
    -- Remove money first
    local moneyRemoved = false
    if paymentMethod == 'cash' then
        moneyRemoved = Player.Functions.RemoveMoney('cash', total, purchaseType == 'vending' and 'vending-purchase' or 'market-purchase')
    elseif paymentMethod == 'bank' then
        moneyRemoved = Player.Functions.RemoveMoney('bank', total, purchaseType == 'vending' and 'vending-purchase' or 'market-purchase')
    end
    
    if not moneyRemoved then
        print('[QG Markets] Failed to remove money from player')
        cb(false, Config.Language['purchase_failed'])
        return
    end
    
    print('[QG Markets] Money removed successfully')
    
    -- Get ox_inventory items
    local oxItems = GetOxItems()
    
    -- Add items to player inventory
    local itemsAdded = 0
    local totalItems = 0

    for _, item in pairs(items) do
        totalItems = totalItems + 1
        local itemData = nil

        -- Vending machine veya market item'ını kontrol et
        if purchaseType == 'vending' and vendingId then
            itemData = GetVendingItem(vendingId, item.name)
        elseif marketId then
            -- For custom stocked markets, use item data from the purchase request
            if locationIndex then
                -- Custom stock - item data comes from the request
                itemData = {
                    name = item.name,
                    label = item.label,
                    price = item.price
                }

                -- Reduce stock and track sale
                ReduceMarketStock(marketId, locationIndex, item.name, item.quantity)
                local itemTotal = item.price * item.quantity
                local stockKey = marketId .. "_" .. locationIndex

                -- Track individual item sale immediately
                local saleItems = {{
                    name = item.name,
                    label = item.label,
                    quantity = item.quantity
                }}
                TriggerEvent('qg_markets:trackSale', stockKey, itemTotal, saleItems, paymentMethod)
            else
                -- Default market - get from config
                itemData = GetMarketItem(marketId, item.name)
            end
        end

        if itemData then
            -- Check if item exists in ox_inventory first, then fallback to QBCore
            local itemExists = false
            
            if oxItems and oxItems[item.name] then
                itemExists = true
                print(string.format('[QG Markets] Item %s found in ox_inventory', item.name))
            elseif QBCore.Shared.Items[item.name] then
                itemExists = true
                print(string.format('[QG Markets] Item %s found in QBCore.Shared.Items', item.name))
            end
            
            if itemExists then
                local success = false
                
                -- Try ox_inventory first
                if GetResourceState('ox_inventory') == 'started' then
                    success = exports.ox_inventory:AddItem(source, item.name, item.quantity)
                    if success then
                        print(string.format('[QG Markets] Added %dx %s via ox_inventory', item.quantity, item.name))
                    end
                end
                
                -- Fallback to QBCore if ox_inventory failed or not available
                if not success then
                    success = Player.Functions.AddItem(item.name, item.quantity)
                    if success then
                        print(string.format('[QG Markets] Added %dx %s via QBCore', item.quantity, item.name))
                        -- Trigger item notification for QBCore
                        if QBCore.Shared.Items[item.name] then
                            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item.name], 'add', item.quantity)
                        end
                    end
                end
                
                if success then
                    itemsAdded = itemsAdded + 1
                else
                    print(string.format('[QG Markets] Failed to add item %s to inventory', item.name))
                end
            else
                print(string.format('[QG Markets] Item %s does not exist in ox_inventory or QBCore.Shared.Items', item.name))
            end
        else
            print(string.format('[QG Markets] Item %s not found in %s %s', item.name, purchaseType, vendingId or marketId))
        end
    end
    
    -- Check if all items were added successfully
    if itemsAdded == totalItems then
        print(string.format('[QG Markets] Purchase successful: %s (%s) bought %d items for $%d using %s', 
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            Player.PlayerData.citizenid,
            totalItems,
            total,
            paymentMethod
        ))
        
        cb(true, Config.Language['purchase_successful'])
    else
        -- Some items failed to add, but money was already removed
        -- In a production system, you might want to refund the money or handle this differently
        print(string.format('[QG Markets] Partial purchase: %d/%d items added', itemsAdded, totalItems))
        cb(true, Config.Language['purchase_successful'] .. ' (Bazı itemlar eklenemedi)')
    end
end)

-- Helper Functions
function GetMarketItem(marketId, itemName)
    local market = Config.Markets[marketId]
    if not market then 
        print('[QG Markets] Market not found: ' .. tostring(marketId))
        return nil 
    end
    
    for _, item in pairs(market.items) do
        if item.name == itemName then
            return item
        end
    end
    
    print('[QG Markets] Item not found in market: ' .. tostring(itemName))
    return nil
end

function GetVendingItem(vendingId, itemName)
    local vending = Config.VendingMachines[vendingId]
    if not vending then 
        print('[QG Markets] Vending machine not found: ' .. tostring(vendingId))
        return nil 
    end
    
    for _, item in pairs(vending.inventory) do
        if item.name == itemName then
            return item
        end
    end
    
    print('[QG Markets] Item not found in vending machine: ' .. tostring(itemName))
    return nil
end

-- Debug command to check available items (remove in production)
QBCore.Commands.Add('checkmarketitems', 'Check available items for market debugging', {}, false, function(source, args)
    local oxItems = GetOxItems()
    local itemCount = 0
    
    if oxItems then
        for itemName, itemData in pairs(oxItems) do
            itemCount = itemCount + 1
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Market Debug", string.format("Ox_inventory loaded with %d items", itemCount)}
        })
    else
        local qbItemCount = 0
        for itemName, itemData in pairs(QBCore.Shared.Items) do
            qbItemCount = qbItemCount + 1
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = true,
            args = {"Market Debug", string.format("Using QBCore items: %d items available", qbItemCount)}
        })
    end
end, 'user')

-- Debug command to check player money (remove in production)
QBCore.Commands.Add('checkmarketmoney', 'Check your money for market debugging', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = true,
            args = {"Market Debug", string.format("Cash: $%d | Bank: $%d", 
                Player.PlayerData.money.cash or 0, 
                Player.PlayerData.money.bank or 0)}
        })
    end
end, 'user')

-- Debug command to check weapon license
QBCore.Commands.Add('checkweaponlicense', 'Check your weapon license status', {}, false, function(source, args)
    local hasLicense = CheckPlayerWeaponLicense(source)

    TriggerClientEvent('chat:addMessage', source, {
        color = hasLicense and {0, 255, 0} or {255, 0, 0},
        multiline = true,
        args = {"License Debug", hasLicense and "You have a weapon license!" or "You do not have a weapon license!"}
    })
end, 'user')

-- Reduce market stock helper function (updated to work with admin_server)
function ReduceMarketStock(marketId, locationIndex, itemName, quantity)
    if not marketId or not locationIndex or not itemName or not quantity then
        print('[QG Markets] ReduceMarketStock: Invalid parameters')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    TriggerEvent('qg_markets:reduceStock', stockKey, itemName, quantity)
    print(string.format('[QG Markets] Triggering stock reduction for %s: -%d %s', stockKey, quantity, itemName))
end