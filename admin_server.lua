local QBCore = exports['qb-core']:GetCoreObject()

-- In-memory storage for market ownership
local MarketOwnership = {}

-- In-memory storage for market stocks (custom inventory per market)
local MarketStocks = {}

-- In-memory storage for market sales (revenue tracking)
local MarketSales = {}

-- In-memory storage for wholesaler orders
local WholesalerOrders = {}

-- File paths for persistence
local ownershipFile = 'market_ownership.json'
local stocksFile = 'market_stocks.json'
local salesFile = 'market_sales.json'
local ordersFile = 'wholesaler_orders.json'

-- Save data to JSON file
local function SaveToFile(filename, data)
    local file = io.open(filename, 'w')
    if file then
        file:write(json.encode(data))
        file:close()
        print('[QG Markets] Saved data to ' .. filename)
        return true
    else
        print('[QG Markets] ERROR: Could not save to ' .. filename)
        return false
    end
end

-- Load data from JSON file
local function LoadFromFile(filename)
    local file = io.open(filename, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        local data = json.decode(content)
        print('[QG Markets] Loaded data from ' .. filename)
        return data
    else
        print('[QG Markets] File not found: ' .. filename)
        return nil
    end
end

-- Save market ownership
local function SaveMarketOwnership()
    SaveToFile(ownershipFile, MarketOwnership)
end

-- Save market stocks
local function SaveMarketStocks()
    SaveToFile(stocksFile, MarketStocks)
end

-- Save market sales
local function SaveMarketSales()
    SaveToFile(salesFile, MarketSales)
end

-- Save wholesaler orders
local function SaveWholesalerOrders()
    SaveToFile(ordersFile, WholesalerOrders)
end

-- Initialize market ownership data
local function InitializeMarketOwnership()
    -- Try to load from file first
    local loadedData = LoadFromFile(ownershipFile)
    if loadedData then
        MarketOwnership = loadedData
        print('[QG Markets] Loaded market ownership from file')
    else
        -- Initialize new data if no file exists
        for marketId, market in pairs(Config.Markets) do
            -- Only initialize supermarket category
            if marketId == 'supermarket' then
                MarketOwnership[marketId] = {}
                for locationIndex, location in ipairs(market.locations) do
                    MarketOwnership[marketId][locationIndex] = {
                        marketId = marketId,
                        locationIndex = locationIndex,
                        price = 50000, -- Default price
                        owner = false, -- Use false instead of nil for better JSON encoding
                        ownerName = false,
                        purchasedAt = false
                    }
                    print(string.format('[QG Markets] Initialized supermarket location %d (owner: %s)', locationIndex, tostring(MarketOwnership[marketId][locationIndex].owner)))
                end
            end
        end
        SaveMarketOwnership()
    end

    local count = 0
    if MarketOwnership['supermarket'] then
        for _ in pairs(MarketOwnership['supermarket']) do
            count = count + 1
        end
    end
    print('[QG Markets] Initialized ' .. count .. ' supermarket locations')
end

-- Initialize market stocks
local function InitializeMarketStocks()
    local loadedData = LoadFromFile(stocksFile)
    if loadedData then
        MarketStocks = loadedData
        print('[QG Markets] Loaded market stocks from file')
    else
        MarketStocks = {}
        SaveMarketStocks()
    end
end

-- Initialize market sales
local function InitializeMarketSales()
    local loadedData = LoadFromFile(salesFile)
    if loadedData then
        MarketSales = loadedData
        print('[QG Markets] Loaded market sales from file')
    else
        MarketSales = {}
        SaveMarketSales()
    end
end

-- Initialize wholesaler orders
local function InitializeWholesalerOrders()
    local loadedData = LoadFromFile(ordersFile)
    if loadedData then
        WholesalerOrders = loadedData
        print('[QG Markets] Loaded wholesaler orders from file')
    else
        WholesalerOrders = {}
        SaveWholesalerOrders()
    end
end

-- Get market ownership data
QBCore.Functions.CreateCallback('qg_markets:getMarketData', function(source, cb)
    -- Debug: Print current ownership state
    print('[QG Markets Admin] Getting market data...')
    for marketId, locations in pairs(MarketOwnership) do
        for locIndex, loc in pairs(locations) do
            print(string.format('  [%s][%s] Owner: %s', marketId, locIndex, tostring(loc.owner)))
        end
    end

    local marketData = {
        markets = MarketOwnership,
        playerCitizenId = nil,
        playerName = nil
    }

    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        marketData.playerCitizenId = Player.PlayerData.citizenid
        marketData.playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        print('[QG Markets Admin] Player info - ID: ' .. marketData.playerCitizenId .. ', Name: ' .. marketData.playerName)
    end

    cb(marketData)
end)

-- Purchase market callback
QBCore.Functions.CreateCallback('qg_markets:purchaseMarket', function(source, cb, marketId, locationIndex, paymentMethod)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if market exists
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market lokasyonu bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]

    -- Check if already owned
    if location.owner and location.owner ~= false then
        cb(false, 'Bu market zaten sahipli!')
        return
    end

    -- Check payment method
    local playerMoney = 0
    if paymentMethod == 'cash' then
        playerMoney = Player.PlayerData.money.cash or 0
    elseif paymentMethod == 'bank' then
        playerMoney = Player.PlayerData.money.bank or 0
    else
        cb(false, 'Geçersiz ödeme yöntemi!')
        return
    end

    -- Check if player has enough money
    if playerMoney < location.price then
        cb(false, 'Yetersiz bakiye! Gerekli: $' .. location.price)
        return
    end

    -- Remove money
    local moneyRemoved = false
    if paymentMethod == 'cash' then
        moneyRemoved = Player.Functions.RemoveMoney('cash', location.price, 'market-purchase')
    elseif paymentMethod == 'bank' then
        moneyRemoved = Player.Functions.RemoveMoney('bank', location.price, 'market-purchase')
    end

    if not moneyRemoved then
        cb(false, 'Para çekme başarısız!')
        return
    end

    -- Set ownership
    location.owner = Player.PlayerData.citizenid
    location.ownerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    location.purchasedAt = os.time()

    -- Save to file
    SaveMarketOwnership()

    print(string.format('[QG Markets] %s purchased %s location #%d for $%d',
        location.ownerName, marketId, locationIndex, location.price))

    -- Return updated data
    local marketData = {
        markets = MarketOwnership,
        playerCitizenId = Player.PlayerData.citizenid,
        playerName = location.ownerName
    }

    -- Initialize empty stock for this market (NO default items)
    local stockKey = marketId .. "_" .. locationIndex
    if not MarketStocks[stockKey] then
        MarketStocks[stockKey] = {}
        SaveMarketStocks()
        print(string.format('[QG Markets] Initialized empty stock for %s', stockKey))
    end

    print(string.format('[QG Markets] Market %s location %d purchased by %s (citizenid: %s)',
        marketId, locationIndex, location.ownerName, location.owner))

    -- Trigger client to update owned markets cache
    print('[QG Markets] Triggering client event qg_markets:client:updateOwnedMarkets for source: ' .. source)
    TriggerClientEvent('qg_markets:client:updateOwnedMarkets', source)

    cb(true, 'Market başarıyla satın alındı!', marketData)
end)

-- Sell market callback
QBCore.Functions.CreateCallback('qg_markets:sellMarket', function(source, cb, marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if market exists
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market lokasyonu bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]

    -- Check if owned by player
    if not location.owner or location.owner == false or location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    -- Calculate sell price (50% of purchase price)
    local sellPrice = math.floor(location.price * 0.5)

    -- Add money back
    Player.Functions.AddMoney('bank', sellPrice, 'market-sale')

    print(string.format('[QG Markets] %s sold %s location #%d for $%d',
        location.ownerName, marketId, locationIndex, sellPrice))

    -- Remove ownership
    location.owner = false
    location.ownerName = false
    location.purchasedAt = false

    -- Save to file
    SaveMarketOwnership()

    -- Clear market stock
    local stockKey = marketId .. "_" .. locationIndex
    MarketStocks[stockKey] = nil
    SaveMarketStocks()

    -- Trigger client to update owned markets cache
    TriggerClientEvent('qg_markets:client:updateOwnedMarkets', source)

    -- Return updated data
    local marketData = {
        markets = MarketOwnership,
        playerCitizenId = Player.PlayerData.citizenid,
        playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    }

    cb(true, 'Market başarıyla satıldı! Geri ödeme: $' .. sellPrice, marketData)
end)

-- Get player owned markets callback
QBCore.Functions.CreateCallback('qg_markets:getPlayerOwnedMarkets', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        print('[QG Markets] getPlayerOwnedMarkets - Player not found for source: ' .. source)
        cb({})
        return
    end

    local citizenId = Player.PlayerData.citizenid
    print('[QG Markets] getPlayerOwnedMarkets - Checking for player: ' .. citizenId)

    local ownedMarkets = {}
    for marketId, locations in pairs(MarketOwnership) do
        for locationIndex, location in pairs(locations) do
            print(string.format('[QG Markets] Checking %s location %d - owner: %s (type: %s)',
                marketId, locationIndex, tostring(location.owner), type(location.owner)))

            if location.owner and location.owner ~= false and location.owner == citizenId then
                table.insert(ownedMarkets, {
                    marketId = marketId,
                    locationIndex = locationIndex
                })
                print(string.format('[QG Markets] Found owned market: %s location %d', marketId, locationIndex))
            end
        end
    end

    print('[QG Markets] Total owned markets for ' .. citizenId .. ': ' .. #ownedMarkets)
    cb(ownedMarkets)
end)

-- Get market stock callback
QBCore.Functions.CreateCallback('qg_markets:getMarketStock', function(source, cb, marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(nil, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(nil, 'Bu market size ait değil!')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    cb(MarketStocks[stockKey] or {})
end)

-- Add stock to market callback
QBCore.Functions.CreateCallback('qg_markets:addStockToMarket', function(source, cb, marketId, locationIndex, itemName, quantity)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    -- Check if player has the item
    local hasItem = false
    if GetResourceState('ox_inventory') == 'started' then
        local itemCount = exports.ox_inventory:Search(source, 'count', itemName)
        hasItem = itemCount >= quantity
    else
        local item = Player.Functions.GetItemByName(itemName)
        hasItem = item and item.amount >= quantity
    end

    if not hasItem then
        cb(false, 'Envanterinizde yeterli item yok!')
        return
    end

    -- Remove item from player
    local removed = false
    if GetResourceState('ox_inventory') == 'started' then
        removed = exports.ox_inventory:RemoveItem(source, itemName, quantity)
    else
        removed = Player.Functions.RemoveItem(itemName, quantity)
    end

    if not removed then
        cb(false, 'Item çıkarılamadı!')
        return
    end

    -- Add to market stock
    local stockKey = marketId .. "_" .. locationIndex
    if not MarketStocks[stockKey] then
        MarketStocks[stockKey] = {}
    end

    -- Get default price from config if exists
    local defaultPrice = 10
    if Config.Markets[marketId] then
        for _, configItem in pairs(Config.Markets[marketId].items) do
            if configItem.name == itemName then
                defaultPrice = configItem.price
                break
            end
        end
    end

    if not MarketStocks[stockKey][itemName] then
        MarketStocks[stockKey][itemName] = {
            quantity = 0,
            price = defaultPrice
        }
    end

    -- Update quantity
    if type(MarketStocks[stockKey][itemName]) == 'number' then
        local oldQuantity = MarketStocks[stockKey][itemName]
        MarketStocks[stockKey][itemName] = {
            quantity = oldQuantity + quantity,
            price = defaultPrice
        }
    else
        MarketStocks[stockKey][itemName].quantity = MarketStocks[stockKey][itemName].quantity + quantity
    end

    -- Save to file
    SaveMarketStocks()

    print(string.format('[QG Markets] %s added %dx %s (price: $%d) to market %s location %d',
        Player.PlayerData.citizenid, quantity, itemName, defaultPrice, marketId, locationIndex))

    cb(true, '', MarketStocks[stockKey])
end)

-- Remove stock from market callback
QBCore.Functions.CreateCallback('qg_markets:removeStockFromMarket', function(source, cb, marketId, locationIndex, itemName, quantity)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    if not MarketStocks[stockKey] or not MarketStocks[stockKey][itemName] then
        cb(false, 'Yeterli stok yok!')
        return
    end

    -- Get current quantity
    local currentQuantity = 0
    if type(MarketStocks[stockKey][itemName]) == 'number' then
        currentQuantity = MarketStocks[stockKey][itemName]
    else
        currentQuantity = MarketStocks[stockKey][itemName].quantity or 0
    end

    if currentQuantity < quantity then
        cb(false, 'Yeterli stok yok!')
        return
    end

    -- Add item to player
    local added = false
    if GetResourceState('ox_inventory') == 'started' then
        added = exports.ox_inventory:AddItem(source, itemName, quantity)
    else
        added = Player.Functions.AddItem(itemName, quantity)
    end

    if not added then
        cb(false, 'Item eklenemedi!')
        return
    end

    -- Remove from market stock
    if type(MarketStocks[stockKey][itemName]) == 'number' then
        MarketStocks[stockKey][itemName] = MarketStocks[stockKey][itemName] - quantity
        if MarketStocks[stockKey][itemName] <= 0 then
            MarketStocks[stockKey][itemName] = nil
        end
    else
        MarketStocks[stockKey][itemName].quantity = MarketStocks[stockKey][itemName].quantity - quantity
        if MarketStocks[stockKey][itemName].quantity <= 0 then
            MarketStocks[stockKey][itemName] = nil
        end
    end

    -- Save to file
    SaveMarketStocks()

    print(string.format('[QG Markets] %s removed %dx %s from market %s location %d',
        Player.PlayerData.citizenid, quantity, itemName, marketId, locationIndex))

    cb(true, '', MarketStocks[stockKey])
end)

-- Get player inventory callback
QBCore.Functions.CreateCallback('qg_markets:getPlayerInventory', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end

    local inventory = {}

    if GetResourceState('ox_inventory') == 'started' then
        local oxItems = exports.ox_inventory:GetInventoryItems(source)
        for _, item in pairs(oxItems) do
            if item.count > 0 then
                table.insert(inventory, {
                    name = item.name,
                    label = item.label,
                    count = item.count
                })
            end
        end
    else
        for _, item in pairs(Player.PlayerData.items) do
            if item and item.amount > 0 then
                table.insert(inventory, {
                    name = item.name,
                    label = item.label,
                    count = item.amount
                })
            end
        end
    end

    cb(inventory)
end)

-- Update item price callback
QBCore.Functions.CreateCallback('qg_markets:updateItemPrice', function(source, cb, marketId, locationIndex, itemName, price)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, '')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, '')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, '')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    if not MarketStocks[stockKey] or not MarketStocks[stockKey][itemName] then
        cb(false, '')
        return
    end

    -- Update price
    if type(MarketStocks[stockKey][itemName]) == 'number' then
        local quantity = MarketStocks[stockKey][itemName]
        MarketStocks[stockKey][itemName] = {
            quantity = quantity,
            price = price
        }
    else
        MarketStocks[stockKey][itemName].price = price
    end

    SaveMarketStocks()

    print(string.format('[QG Markets] %s updated price for %s to $%d in market %s location %d',
        Player.PlayerData.citizenid, itemName, price, marketId, locationIndex))

    cb(true, '', MarketStocks[stockKey])
end)

-- Event handler for reducing stock
RegisterNetEvent('qg_markets:reduceStock', function(stockKey, itemName, quantity)
    if not MarketStocks[stockKey] then return end
    if not MarketStocks[stockKey][itemName] then return end

    if type(MarketStocks[stockKey][itemName]) == 'number' then
        MarketStocks[stockKey][itemName] = math.max(0, MarketStocks[stockKey][itemName] - quantity)
        if MarketStocks[stockKey][itemName] <= 0 then
            MarketStocks[stockKey][itemName] = nil
        end
    else
        MarketStocks[stockKey][itemName].quantity = math.max(0, MarketStocks[stockKey][itemName].quantity - quantity)
        if MarketStocks[stockKey][itemName].quantity <= 0 then
            MarketStocks[stockKey][itemName] = nil
        end
    end

    SaveMarketStocks()
    print(string.format('[QG Markets] Reduced stock: %s -%d for %s', itemName, quantity, stockKey))
end)

-- Get market stock for purchase (with pricing info)
QBCore.Functions.CreateCallback('qg_markets:getMarketStockForPurchase', function(source, cb, marketId, locationIndex)
    local stockKey = marketId .. "_" .. locationIndex

    -- Check if this market has an owner
    local hasOwner = false
    if MarketOwnership[marketId] and MarketOwnership[marketId][locationIndex] then
        local location = MarketOwnership[marketId][locationIndex]
        hasOwner = location.owner and location.owner ~= false
    end

    -- If no owner, return nil to use config default items
    if not hasOwner then
        cb(nil, false)
        return
    end

    -- Market has owner, check stock
    if not MarketStocks[stockKey] then
        -- Owner exists but no stock table = empty market
        cb({}, true)
        return
    end

    -- Check if there's any stock
    local hasStock = false
    for _, _ in pairs(MarketStocks[stockKey]) do
        hasStock = true
        break
    end

    if not hasStock then
        -- Owner exists but stock is empty = empty market
        cb({}, true)
        return
    end

    -- Get ox_inventory items
    local oxItems = nil
    if GetResourceState('ox_inventory') == 'started' then
        oxItems = exports.ox_inventory:Items()
    end

    -- Convert stock to items format
    local items = {}
    local itemImages = {}
    for itemName, data in pairs(MarketStocks[stockKey]) do
        local quantity = type(data) == 'number' and data or (data.quantity or 0)
        local price = type(data) == 'number' and 10 or (data.price or 10)

        -- Get item label and image from ox_inventory first
        local itemLabel = itemName
        local itemImage = itemName .. '.png'
        if oxItems and oxItems[itemName] then
            itemLabel = oxItems[itemName].label or itemName
            itemImage = oxItems[itemName].image or (itemName .. '.png')
        end

        -- Get category from config if exists
        local itemCategory = 'general'
        if Config.Markets[marketId] then
            for _, item in pairs(Config.Markets[marketId].items) do
                if item.name == itemName then
                    itemCategory = item.category or 'general'
                    break
                end
            end
        end

        if quantity and quantity > 0 then
            table.insert(items, {
                name = itemName,
                label = itemLabel,
                price = price,
                category = itemCategory,
                stock = quantity
            })
            itemImages[itemName] = itemImage
        end
    end

    cb(items, true, itemImages)
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000)
    InitializeMarketOwnership()
    InitializeMarketStocks()
    InitializeMarketSales()
    InitializeWholesalerOrders()
end)

-- Auto-save every 5 minutes
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        SaveMarketOwnership()
        SaveMarketStocks()
        SaveMarketSales()
        SaveWholesalerOrders()
        print('[QG Markets] Auto-saved market data')
    end
end)

-- Get market sales callback
QBCore.Functions.CreateCallback('qg_markets:getMarketSales', function(source, cb, marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil, '')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(nil, '')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(nil, '')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    local salesData = MarketSales[stockKey] or {
        totalRevenue = 0,
        totalSales = 0,
        lastCollected = false,
        salesHistory = {}
    }

    cb(salesData)
end)

-- Collect revenue callback
QBCore.Functions.CreateCallback('qg_markets:collectRevenue', function(source, cb, marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    local stockKey = marketId .. "_" .. locationIndex
    local salesData = MarketSales[stockKey] or { totalRevenue = 0 }

    if salesData.totalRevenue <= 0 then
        cb(false, '')
        return
    end

    -- Add money to player
    Player.Functions.AddMoney('bank', salesData.totalRevenue, 'market-revenue-collection')

    print(string.format('[QG Markets] %s collected $%d revenue from market %s location %d',
        Player.PlayerData.citizenid, salesData.totalRevenue, marketId, locationIndex))

    local collectedAmount = salesData.totalRevenue

    -- Reset revenue
    salesData.totalRevenue = 0
    salesData.lastCollected = os.time()
    MarketSales[stockKey] = salesData

    SaveMarketSales()

    cb(true, '', collectedAmount, salesData)
end)

-- Track sale event (called when a purchase is made)
RegisterNetEvent('qg_markets:trackSale', function(stockKey, amount, items, paymentMethod)
    if not MarketSales[stockKey] then
        MarketSales[stockKey] = {
            totalRevenue = 0,
            totalSales = 0,
            lastCollected = false,
            salesHistory = {}
        }
    end

    MarketSales[stockKey].totalRevenue = MarketSales[stockKey].totalRevenue + amount
    MarketSales[stockKey].totalSales = MarketSales[stockKey].totalSales + 1

    -- Add sale to history
    if not MarketSales[stockKey].salesHistory then
        MarketSales[stockKey].salesHistory = {}
    end

    table.insert(MarketSales[stockKey].salesHistory, {
        timestamp = os.time(),
        total = amount,
        items = items or {},
        paymentMethod = paymentMethod or 'cash'
    })

    -- Keep only last 50 sales in history
    if #MarketSales[stockKey].salesHistory > 50 then
        table.remove(MarketSales[stockKey].salesHistory, 1)
    end

    SaveMarketSales()
    print(string.format('[QG Markets] Tracked sale: $%d for %s (Total: $%d)',
        amount, stockKey, MarketSales[stockKey].totalRevenue))
end)

-- Employee Management
-- Get market employees
QBCore.Functions.CreateCallback('qg_markets:getMarketEmployees', function(source, cb, marketId, locationIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(nil, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(nil, 'Bu market size ait değil!')
        return
    end

    local employees = location.employees or {}
    cb(employees)
end)

-- Add employee
QBCore.Functions.CreateCallback('qg_markets:addEmployee', function(source, cb, marketId, locationIndex, targetCitizenId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    -- Find the target player by citizenid
    local targetPlayer = nil
    for _, playerSource in pairs(QBCore.Functions.GetPlayers()) do
        local tempPlayer = QBCore.Functions.GetPlayer(playerSource)
        if tempPlayer and tempPlayer.PlayerData.citizenid == targetCitizenId then
            targetPlayer = tempPlayer
            break
        end
    end

    if not targetPlayer then
        cb(false, 'Oyuncu bulunamadı veya çevrimiçi değil!')
        return
    end

    -- Initialize employees table if not exists
    if not location.employees then
        location.employees = {}
    end

    -- Check if already employee
    if location.employees[targetCitizenId] then
        cb(false, 'Bu kişi zaten çalışan!')
        return
    end

    -- Add employee
    location.employees[targetCitizenId] = {
        citizenId = targetCitizenId,
        name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        addedAt = os.time()
    }

    SaveMarketOwnership()

    print(string.format('[QG Markets] %s added employee %s to market %s location %d',
        Player.PlayerData.citizenid, targetCitizenId, marketId, locationIndex))

    cb(true, 'Çalışan başarıyla eklendi!', location.employees)
end)

-- WHOLESALER SYSTEM

-- Place wholesaler order
QBCore.Functions.CreateCallback('qg_markets:placeWholesalerOrder', function(source, cb, marketId, locationIndex, items, expressDelivery, paymentMethod)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    local totalCost = 0
    for _, item in ipairs(items) do
        totalCost = totalCost + (item.price * item.quantity)
    end

    if expressDelivery then
        totalCost = math.floor(totalCost * Config.Wholesaler.expressDeliveryMultiplier)
    end

    paymentMethod = paymentMethod or 'bank'

    if Player.PlayerData.money[paymentMethod] < totalCost then
        local methodName = paymentMethod == 'cash' and 'nakit' or 'banka'
        cb(false, 'Yetersiz ' .. methodName .. ' bakiyesi!')
        return
    end

    if not Player.Functions.RemoveMoney(paymentMethod, totalCost, 'wholesaler-order') then
        cb(false, 'Ödeme başarısız!')
        return
    end

    local deliveryTime = Config.Wholesaler.baseDeliveryTime
    if expressDelivery then
        deliveryTime = math.floor(deliveryTime * Config.Wholesaler.expressDeliveryTimeReduction)
    end

    local orderId = 'order_' .. os.time() .. '_' .. source
    local order = {
        orderId = orderId,
        marketId = marketId,
        locationIndex = locationIndex,
        owner = Player.PlayerData.citizenid,
        items = items,
        totalCost = totalCost,
        expressDelivery = expressDelivery,
        placedAt = os.time(),
        deliveryAt = os.time() + deliveryTime,
        status = 'pending'
    }

    WholesalerOrders[orderId] = order
    SaveWholesalerOrders()

    print(string.format('[QG Markets] Order %s placed by %s for market %s location %d - Cost: $%d, Delivery in: %d seconds',
        orderId, Player.PlayerData.citizenid, marketId, locationIndex, totalCost, deliveryTime))

    cb(true, 'Sipariş başarıyla oluşturuldu!', order)
end)

-- Get player's pending orders
QBCore.Functions.CreateCallback('qg_markets:getPlayerOrders', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end

    local playerOrders = {}
    for orderId, order in pairs(WholesalerOrders) do
        if order.owner == Player.PlayerData.citizenid and (order.status == 'pending' or order.status == 'ready') then
            table.insert(playerOrders, order)
        end
    end

    cb(playerOrders)
end)

-- Collect wholesaler order (manual pickup)
QBCore.Functions.CreateCallback('qg_markets:collectWholesalerOrder', function(source, cb, orderId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    local order = WholesalerOrders[orderId]
    if not order then
        cb(false, 'Sipariş bulunamadı!')
        return
    end

    if order.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu sipariş size ait değil!')
        return
    end

    if order.status ~= 'ready' then
        cb(false, 'Sipariş henüz hazır değil!')
        return
    end

    -- Add items to player inventory instead of market stock
    local itemsAdded = 0
    local totalItems = 0

    for _, item in ipairs(order.items) do
        totalItems = totalItems + 1
        local success = false

        -- Try ox_inventory first
        if GetResourceState('ox_inventory') == 'started' then
            success = exports.ox_inventory:AddItem(source, item.name, item.quantity)
            if success then
                print(string.format('[QG Markets] Added %dx %s to player inventory via ox_inventory', item.quantity, item.name))
            end
        end

        -- Fallback to QBCore if ox_inventory failed or not available
        if not success then
            success = Player.Functions.AddItem(item.name, item.quantity)
            if success then
                print(string.format('[QG Markets] Added %dx %s to player inventory via QBCore', item.quantity, item.name))
                -- Trigger item notification for QBCore
                if QBCore.Shared.Items[item.name] then
                    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[item.name], 'add', item.quantity)
                end
            end
        end

        if success then
            itemsAdded = itemsAdded + 1
        else
            print(string.format('[QG Markets] Failed to add item %s to player inventory', item.name))
        end
    end

    if itemsAdded == totalItems then
        order.status = 'collected'
        SaveWholesalerOrders()

        print(string.format('[QG Markets] Order %s collected by %s - %d items added to inventory',
            orderId, Player.PlayerData.citizenid, itemsAdded))

        cb(true, 'Sipariş teslim alındı! Ürünler envanterinize eklendi.')
    else
        print(string.format('[QG Markets] Partial collection: %d/%d items added to inventory', itemsAdded, totalItems))
        cb(false, 'Envanterinizde yeterli alan yok!')
    end
end)

-- Check and mark orders as ready for pickup (NOT auto-delivered)
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds for accuracy

        local currentTime = os.time()
        for orderId, order in pairs(WholesalerOrders) do
            if order.status == 'pending' and currentTime >= order.deliveryAt then
                order.status = 'ready' -- Mark as ready for pickup instead of delivered
                SaveWholesalerOrders()

                print(string.format('[QG Markets] Order %s is ready for pickup at market %s location %d',
                    orderId, order.marketId, order.locationIndex))

                local ownerSource = nil
                for _, playerSource in pairs(QBCore.Functions.GetPlayers()) do
                    local tempPlayer = QBCore.Functions.GetPlayer(playerSource)
                    if tempPlayer and tempPlayer.PlayerData.citizenid == order.owner then
                        ownerSource = playerSource
                        break
                    end
                end

                if ownerSource then
                    TriggerClientEvent('ox_lib:notify', ownerSource, {
                        title = 'Toptancı',
                        description = 'Siparişiniz teslim almaya hazır!',
                        type = 'info'
                    })
                end
            end
        end
    end
end)

-- Remove employee
QBCore.Functions.CreateCallback('qg_markets:removeEmployee', function(source, cb, marketId, locationIndex, targetCitizenId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    if not location.employees or not location.employees[targetCitizenId] then
        cb(false, 'Bu kişi çalışan değil!')
        return
    end

    -- Remove employee
    location.employees[targetCitizenId] = nil

    SaveMarketOwnership()

    print(string.format('[QG Markets] %s removed employee %s from market %s location %d',
        Player.PlayerData.citizenid, targetCitizenId, marketId, locationIndex))

    cb(true, 'Çalışan başarıyla çıkarıldı!', location.employees)
end)

-- Add employee by server ID (scan nearby players)
QBCore.Functions.CreateCallback('qg_markets:addEmployeeByServerId', function(source, cb, marketId, locationIndex, targetServerId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    -- Check if player owns this market
    if not MarketOwnership[marketId] or not MarketOwnership[marketId][locationIndex] then
        cb(false, 'Market bulunamadı!')
        return
    end

    local location = MarketOwnership[marketId][locationIndex]
    if location.owner ~= Player.PlayerData.citizenid then
        cb(false, 'Bu market size ait değil!')
        return
    end

    -- Get target player
    local targetPlayer = QBCore.Functions.GetPlayer(targetServerId)
    if not targetPlayer then
        cb(false, 'Oyuncu bulunamadı!')
        return
    end

    local targetCitizenId = targetPlayer.PlayerData.citizenid

    -- Initialize employees table if not exists
    if not location.employees then
        location.employees = {}
    end

    -- Check if already employee
    if location.employees[targetCitizenId] then
        cb(false, 'Bu kişi zaten çalışan!')
        return
    end

    -- Add employee
    location.employees[targetCitizenId] = {
        citizenId = targetCitizenId,
        name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        addedAt = os.time()
    }

    SaveMarketOwnership()

    print(string.format('[QG Markets] %s added employee %s to market %s location %d',
        Player.PlayerData.citizenid, targetCitizenId, marketId, locationIndex))

    cb(true, 'Çalışan başarıyla eklendi!', location.employees)
end)
