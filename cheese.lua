local sampleInterval = 1
local itemName = nil
local data = {}

local me = peripheral.find("me_bridge")
local monitor = peripheral.find("monitor")

print("Enter the item name to track (e.g., minecraft:dirt):")
itemName = read()

local function getItemQuantity()
    local items = me.getItems()
    for _, item in ipairs(items) do
        if item.name == itemName then
            return item.count or 0
        end
    end
    return 0
end

local function drawGraph()
    monitor.clear()
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1, 1)
    if #data == 0 then
        monitor.write("No data yet.")
        return
    end

    local width, height = monitor.getSize()
    local graphHeight = height - 2
    local numPoints = math.min(#data, width)
    local minQuantity = data[#data - numPoints + 1].quantity
    local maxQuantity = minQuantity
    for i = 1, numPoints do
        local qty = data[#data - numPoints + i].quantity
        if qty < minQuantity then minQuantity = qty end
        if qty > maxQuantity then maxQuantity = qty end
    end
    local range = maxQuantity - minQuantity
    if range == 0 then range = 1 end

    local quantity = data[#data].quantity
    local prevQuantity = #data > 1 and data[#data - 1].quantity or nil
    local qtyColor = colors.white
    if prevQuantity then
        if quantity > prevQuantity then
            qtyColor = colors.green
        elseif quantity < prevQuantity then
            qtyColor = colors.red
        end
    end
    monitor.write("Item: " .. itemName)
    monitor.setTextColor(qtyColor)
    monitor.setCursorPos(width - #tostring(quantity), 1)
    monitor.write(tostring(quantity))
    monitor.setTextColor(colors.white)

    for col = 1, numPoints do
        local entry = data[#data - numPoints + col]
        local normalized = (entry.quantity - minQuantity) / range
        local barHeight = math.max(1, math.floor(normalized * graphHeight + 0.5))
        local color = colors.white
        local prevHeight = nil
        local prevEntry = nil
        if col > 1 then
            prevEntry = data[#data - numPoints + col - 1]
            local prevNormalized = (prevEntry.quantity - minQuantity) / range
            prevHeight = math.max(1, math.floor(prevNormalized * graphHeight + 0.5))
            if entry.quantity > prevEntry.quantity then
                color = colors.green
            elseif entry.quantity < prevEntry.quantity then
                color = colors.red
            end
        end

        for y = 1, graphHeight do
            monitor.setCursorPos(col, height - y)
            if y == barHeight then
                monitor.setTextColor(color)
                monitor.write("#")
            elseif col > 1 then
                if y > barHeight and y <= prevHeight and entry.quantity < prevEntry.quantity then
                    monitor.setTextColor(colors.red)
                    monitor.write("|")
                elseif y < barHeight and y >= prevHeight and entry.quantity > prevEntry.quantity then
                    monitor.setTextColor(colors.green)
                    monitor.write("|")
                else
                    monitor.write(" ")
                end
            else
                monitor.write(" ")
            end
        end
    end
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1, height)
    monitor.write("Oldest")
    monitor.setCursorPos(width - 5, height)
    monitor.write("Newest")
end

while true do
    local quantity = getItemQuantity()
    local time = os.time()
    table.insert(data, {time = time, quantity = quantity})

    local width = select(1, monitor.getSize())
    if #data > width * 2 then
        table.remove(data, 1)
    end

    drawGraph()

    print("Quantity: " .. quantity)

    sleep(sampleInterval)
end
