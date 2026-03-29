local Script = {}

local tx = {
2918,--框选
1260,--蓝色
1261,--黄色
1262--绿色
}
local 建造锤id = {
    ["r2_7619679675441318548_65162"] = {name="石制建筑锤", i=81},
    ["r2_7619679001131453076_65138"] = {name="黄铜建筑锤", i=361},
    ["r2_7619680087758178964_65223"] = {name="铁制建筑锤",i=841},
    ["r2_7619680405585758868_65284"] = {name="钛金建筑锤", i=1521}
}
-- 组件启动时调用
function Script:OnStart()
    self.V = self.V or {}
    self:AddTriggerEvent(TriggerEvent.PlayerUseItem, self.使用道具)
    self:AddTriggerEvent(TriggerEvent.PlayerClickBlock, self.点击方块)
    self:AddTriggerEvent(TriggerEvent.PlayerSelectShortcut, self.选中快捷栏)
    self:AddTriggerEvent(TriggerEvent.GameAnyPlayerEnterGame, self.进入游戏)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyDown, self.按下按键, KeyCode.Shift)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyUp, self.抬起按键, KeyCode.Shift)
    self:AddTriggerEvent(TriggerEvent.PlayerInputKeyClick, self.点击按键, KeyCode.Shift)
end

function Script:进入游戏(e)
    self.V[e.eventobjid] = self.V[e.eventobjid] or{}
end

function Script:按下按键(e)
    local uin = e.eventobjid
    if Player:GetClientInfo(uin) ~= 1 then
        return
    end
    if self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = true
end

function Script:抬起按键(e)
    local uin = e.eventobjid
    if Player:GetClientInfo(uin) ~= 1 then
        return
    end
    if self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = false
end

function Script:点击按键(e)
    local uin  = e.eventobjid
    if Player:GetClientInfo(uin) == 1 then
        return
    end
    if self.V[uin] == nil then
        return
    end
    self.V[uin]["潜行状态"] = not(self.V[uin]["潜行状态"] or false)
end

function Script:获取表面位置(uin, l)
    local x, y, z = Actor:GetPosition(uin)
    y = y + 1.5
    local pitch = math.rad(Actor:GetFacePitch(uin))
    local yaw = math.rad(Actor:GetFaceYaw(uin))
    local cos_p, sin_p = math.cos(pitch), math.sin(pitch)
    local cos_y, sin_y = math.cos(yaw), math.sin(yaw)
    local vx = -cos_p * sin_y
    local vy = -sin_p
    local vz = -cos_p * cos_y
    
    local t = 0
    local ax, ay, az = 1.0/vx, 1.0/vy, 1.0/vz
    local ex, ey, ez = ax < 0 and -ax or ax, ay < 0 and -ay or ay, az < 0 and -az or az
    local tx = 0.5 * (ex + ax) - (x % 1) * ax
    local ty = 0.5 * (ey + ay) - (y % 1) * ay
    local tz = 0.5 * (ez + az) - (z % 1) * az
    tx = tx == tx and tx or math.huge
    ty = ty == ty and ty or math.huge
    tz = tz == tz and tz or math.huge
    local px, py, pz = 0, 0, 0
    while t < l do
        local checkX = math.floor(x + t*vx + 0.5*px)
        local checkY = math.floor(y + t*vy + 0.5*py)
        local checkZ = math.floor(z + t*vz + 0.5*pz)

        if Block:IsSolidBlock(checkX, checkY, checkZ, WorldId) then
            return {x = x + t*vx,y = y + t*vy,z = z + t*vz}
        end

        if tx < ty and tx < tz then
            t = tx
            tx = tx + ex
            px = vx >= 0 and 1 or -1
            py, pz = 0, 0
        elseif ty < tz then
            t = ty
            ty = ty + ey
            py = vy >= 0 and 1 or -1
            px, pz = 0, 0
        else
            t = tz
            tz = tz + ez
            pz = vz >= 0 and 1 or -1
            px, py = 0, 0
        end
    end
    return {x = x + vx * l,y = y + vy * l,z = z + vz * l}
end


function Script:创建特效(uin, t, id, data, index)
    local Durable = Backpack:GetGridAttr(uin, index, GridAttr.Durable)
    for k ,v in ipairs(t) do
        if Durable < k then
            break
        end
       while true do
            local wz = {x = v.x, y = v.y, z = v.z}
            local isAirBlock = Block:IsAirBlock(v.x, v.y, v.z, WorldId)
            if isAirBlock then
                World:PlayParticle(wz, tx[1], 600, WorldId)
                t[k]["hx"] = 1
                break
            end
            -- local blockID = Block:GetBlockID(v.x, v.y, v.z, WorldId)
            -- if blockID == id then
            --     local blockData = Block:GetBlockData(v.x, v.y, v.z, WorldId)
            --     if blockData ~= data then
            --         World:PlayParticle(wz, tx[2], 600, WorldId)
            --         t[k]["hx"] = 2
            --     end
            --     break
            -- end
            local isLiquidBlock = Block:IsLiquidBlock(v.x, v.y, v.z, WorldId)
            if isLiquidBlock then
                World:PlayParticle(wz, tx[4], 600, WorldId)
                t[k]["hx"] = 4
                break
            end
            local IsSolidBlock = Block:IsSolidBlock(v.x, v.y, v.z, WorldId)
            if IsSolidBlock then
                World:PlayParticle(wz, tx[3], 600, WorldId)
                t[k]["hx"] = 3
            end
            break
        end
    end
end

function Script:删除特效(uin, t)
    for k ,v in ipairs(t) do
        World:StopParticleOnPos(v.x, v.y, v.z, tx[v.hx], WorldId)
    end
end

function Script:获取相对位置表(uin, blockID, 位置, 表面位置, 搜索限度)
    local t = {}
    local Dx, Dy, Dz = 位置.x - 表面位置.x, 位置.y - 表面位置.y, 位置.z - 表面位置.z
    local eps = 0.001
    
    local x方向 = (math.abs(Dx) < eps and -1) or (math.abs(Dx + 1) < eps and 1) or nil
    local y方向 = (math.abs(Dy) < eps and -1) or (math.abs(Dy + 1) < eps and 1) or nil
    local z方向 = (math.abs(Dz) < eps and -1) or (math.abs(Dz + 1) < eps and 1) or nil
    
    local num = Backpack:GetItemNum(uin, blockID, false)
    local 上限 = math.min(搜索限度, num)
    if 上限 <= 0 then return {} end
    
    local dirs
    if x方向 then
        dirs = {{0,1,0},{0,-1,0},{0,0,1},{0,0,-1},{0,1,1},{0,1,-1},{0,-1,1},{0,-1,-1}}
    elseif y方向 then
        dirs = {{1,0,0},{-1,0,0},{0,0,1},{0,0,-1},{1,0,1},{1,0,-1},{-1,0,1},{-1,0,-1}}
    elseif z方向 then
        dirs = {{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{1,1,0},{1,-1,0},{-1,1,0},{-1,-1,0}}
    else
        return {}
    end
    
    local v, q, h = {}, {}, 1
    q[h] = {位置.x, 位置.y, 位置.z}
    v[位置.x .. "," .. 位置.y .. "," .. 位置.z] = true
    
    while h <= #q and #t < 上限 do
        local c = q[h]
        h = h + 1
        
        if Block:GetBlockID(c[1], c[2], c[3], WorldId) == blockID then
            local bx, by, bz
            if x方向 then
                bx, by, bz = c[1] + x方向, c[2], c[3]
            elseif y方向 then
                bx, by, bz = c[1], c[2] + y方向, c[3]
            else
                bx, by, bz = c[1], c[2], c[3] + z方向
            end
            
            if Block:IsAirBlock(bx, by, bz, WorldId) then
                table.insert(t, {x=bx, y=by, z=bz, hx=0, data=Block:GetBlockData(c[1], c[2], c[3], WorldId)})
            end
            
            for _, d in ipairs(dirs) do
                local nx, ny, nz = c[1] + d[1], c[2] + d[2], c[3] + d[3]
                local nk = nx .. "," .. ny .. "," .. nz
                if not v[nk] then
                    v[nk] = true
                    table.insert(q, {nx, ny, nz})
                end
            end
        end
    end
    return t
end

function Script:点击方块(e)
    local uin, id, x, y, z = e.eventobjid, e.blockid, e.x, e.y, e.z
    local index = Player:GetShotcutIndex(uin) + BackpackBeginIndex.Shortcut - 1
    local itemid, num = Backpack:GetGridItemID(uin, index)
    if itemid == 0 or num == 0 then
        return
    end
    local 建造锤属性 = 建造锤id[itemid]
    if not 建造锤属性 then
        return
    end
    if self.V[uin] and self.V[uin]["t"] and #self.V[uin]["t"] ~= 0 then
        self:删除特效(uin, self.V[uin]["t"])
        self.V[uin]["t"] = nil
        self.V[uin]["a"] = nil
    end

    local data = Block:GetBlockData(x, y, z, WorldId)
    local 表面位置 = self:获取表面位置(uin, Actor:GetAttr(uin, CreatureAttr.AttackDis)+4)
    local t = self:获取相对位置表(uin, id, {x=x, y=y, z=z}, 表面位置, 建造锤属性.i)
    --print(t)
    self:创建特效(uin, t, id, data, index)
    self.V[uin]["t"] = t
    self.V[uin]["a"] = {data=data, id=id}
end

function Script:使用道具(e)
    local uin, itemid = e.eventobjid, e.itemid
    if not 建造锤id[itemid] then
        return
    end
    if not self.V[uin] or not self.V[uin]["t"] or not self.V[uin]["a"] then
        return
    end
    if #self.V[uin]["t"] == 0 then
        return
    end
    local index = Player:GetShotcutIndex(uin) + BackpackBeginIndex.Shortcut - 1
    self:创建方块(uin, index, self.V[uin]["t"], self.V[uin]["a"]["data"], self.V[uin]["a"]["id"])
    self:删除特效(uin, self.V[uin]["t"])
    self.V[uin]["t"] = nil
    self.V[uin]["a"] = nil
end

function Script:选中快捷栏(e)
    local uin, itemid = e.eventobjid, e.itemid
    if 建造锤id[itemid] then
        Actor:SetActorPermissions(uin, Ability.Break, false)
        return
    end
    Actor:SetActorPermissions(uin, Ability.Break, true)
    if not self.V[uin] or not self.V[uin]["t"] or not self.V[uin]["a"] then
        return
    end
    self:删除特效(uin, self.V[uin]["t"])
    self.V[uin]["t"] = nil
    self.V[uin]["a"] = nil
end
    

function Script:创建方块(uin, index, t, data, id)
    local num = Backpack:GetItemNum(uin, id, false)
    local qx = self.V[uin]["潜行状态"]
    if num == 0 then
        return
    end
    local Durable = Backpack:GetGridAttr(uin, index, GridAttr.Durable)
    if Durable <= 0 then
        return
    end
    local tab = {}
    for k ,v in ipairs(t) do
        if k > Durable then
            break
        end
        if Block:IsAirBlock(v.x, v.y, v.z, WorldId) then
            table.insert(tab, v)
        end
    end


    local i = 0
    for k ,v in ipairs(tab) do
        local ret = Backpack:RemoveGridItemByItemID(uin, id, 1)
        if not (ret and ret > 0) then
            break
        end
        local result = Block:SetBlockAll(v.x, v.y, v.z, id, qx and data or v.data, worldId)
        if not result then
            i = i + 1
        end
    end
    if i > 0 then
        Backpack:CreateItem(uin, id, i)
    end
    Backpack:SetGridAttr(uin, index, GridAttr.Durable, Durable - #tab + i)
end

return Script
