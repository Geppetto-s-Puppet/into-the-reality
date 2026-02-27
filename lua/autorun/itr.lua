CreateConVar("itr","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_fly","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_duck","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_flash","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

CreateConVar("itr_slow","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_fall","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_shoot","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_noclip","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

CreateConVar("itr_hud","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_head","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_sway","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})
CreateConVar("itr_screen","1",{FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

resource.AddFile("materials/bodycam2.vmt") resource.AddFile("materials/bodycam2.vtf")

hook.Add("PopulateToolMenu", "ItR", function()
    spawnmenu.AddToolMenuOption("Options", "Into the Reality", "itr", "Options", "", "", function(pnl)
        pnl:ClearControls()
        pnl:Help("※ Restart the game to apply changed settings.")
        pnl:CheckBox("ENABLE ALL EFFECTS", "itr")
        pnl:CheckBox("Enable muzzle flash.", "itr_flash")
        pnl:CheckBox("Enable toggle crouch/duck.", "itr_duck")
        pnl:CheckBox("Enable minecraft-like flight.", "itr_fly")
        
        pnl:CheckBox("Enable hidden HUD.", "itr_hud")
        pnl:CheckBox("Enable camera bob.", "itr_head")
        pnl:CheckBox("Enable weapon sway.", "itr_sway")
        pnl:CheckBox("Enable realistic post-processing.", "itr_screen")

        pnl:CheckBox("Enable modified movement.", "itr_slow")
        pnl:CheckBox("Enable realistic fall damage.", "itr_fall")
        pnl:CheckBox("Enable reduced bullet impacts.", "itr_shoot")
        pnl:CheckBox("Enable Invisible Invincible Noclipping.", "itr_noclip")
        -- pnl:NumSlider("Material multiplier", "ubp_penetration_multiplier", 0, 10, 1)
    end) end) if not GetConVar("itr"):GetBool() then return

elseif SERVER then

        if GetConVar("itr_slow"):GetBool() then
            hook.Add("PlayerLoadout","ItR_Slow",function(ply) ply:SetDuckSpeed(0.2) ply:SetUnDuckSpeed(0.2) ply:SetWalkSpeed(135) ply:SetRunSpeed(270) end)
            end

        if GetConVar("itr_shoot"):GetBool() then
            hook.Add("EntityFireBullets","ItR_Shoot",function(ent,data) data.Force = data.Force * 0.2 end)
            end

        RunConsoleCommand("mp_falldamage", tostring(GetConVar("itr_fall"):GetInt()))

        if GetConVar("itr_noclip"):GetBool() then
            hook.Add("Think", "ItR_Noclip", function()
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply:GetMoveType() == MOVETYPE_NOCLIP then
                        ply:SetBloodColor(-1) ply:SetNoTarget(true) ply:GodEnable()
                    else
                        ply:SetBloodColor(0) ply:SetNoTarget(false) ply:GodDisable()
                    end end end)
            end

elseif CLIENT then

        if GetConVar("itr_screen"):GetBool() then
            local mat = Material("bodycam2.vmt")
            hook.Add("RenderScreenspaceEffects", "ItR_Screen", function() -- PostDrawEffectsだと銃のスコープに競合
            -- mat:SetFloat("$c0_x", 1 / ScrW()) mat:SetFloat("$c0_y", 1 / ScrH())
            render.UpdateScreenEffectTexture()
            render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())
            render.SetMaterial(mat) render.DrawScreenQuad()
            DrawMotionBlur(0.9,1.0,0.0) end)
            end

        if GetConVar("itr_hud"):GetBool() then
            hook.Add("HUDShouldDraw","ItR_HUD1",function(name) if (name == "CHudCrosshair") and (LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP) then return false end end)
            local hide = {["CHudHealth"] = true,["CHudBattery"] = true,["CHudAmmo"] = true,["CHudSecondaryAmmo"] = true,["CHudDamageIndicator"] = true}
            hook.Add("HUDDrawTargetID","ItR_HUD2",function() return false end) hook.Add("HUDDrawPickupHistory","ItR_HUD3",function() return false end)
            -- hook.Add("PreDrawViewModel","ItR_HUD4", function() if (LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP) then return true end end)
            hook.Add("HUDShouldDraw","ItR_HUD5",function(name) if hide[name] then return false end end)
            RunConsoleCommand("hud_deathnotice_time","0")
            end

        if GetConVar("itr_sway"):GetBool() then
            local function VectorMA(p,q,n,r) r.x = p.x + q.x*n r.y = p.y + q.y*n r.z = p.z + q.z*n end
            hook.Add("CalcViewModelView","ItR_Sway",function(weapon, vm, oldPos, oldAng, pos, ang)
            vm.m_vecLastFacing = vm.m_vecLastFacing or ang:Forward() if FrameTime() == 0 then return end
            VectorMA(vm.m_vecLastFacing, ang:Forward() - vm.m_vecLastFacing, FrameTime()*4, vm.m_vecLastFacing)
            vm.m_vecLastFacing:Normalize()  VectorMA(pos,  ang:Forward()  -  vm.m_vecLastFacing,  -4,  pos)  end)
            end

        if GetConVar("itr_head"):GetBool() then
            local da,dx,dt,lo,le = Angle(0,0,0),0,0,0,Vector(0,0,0)
            local function Hash(n)
                n = bit.band(n, 0x7FFFFFFF) n = bit.bxor(n, bit.rshift(n, 16)) * 0x85ebca6b
                n = bit.band(n, 0x7FFFFFFF) n = bit.bxor(n, bit.rshift(n, 13)) * 0xc2b2ae35
                n = bit.band(n, 0x7FFFFFFF) n = bit.bxor(n, bit.rshift(n, 16)) return n / 2147483647 end
            local function Noise(t, seed)
                seed = seed or 0 local x = math.floor(t) local frac = t - x
                local h1 = Hash(x + seed) * 2 - 1 local h2 = Hash(x + 1 + seed) * 2 - 1
                local smooth = frac * frac * (3 - 2 * frac) return h1 + (h2 - h1) * smooth end
            hook.Add("CalcView","ItR_Head",function(ply, pos, ang)
                if !(ply:GetMoveType() == MOVETYPE_NOCLIP) and ply:Alive() then local vel = ply:GetVelocity()*0.01 local spd = vel:Length() ang=ang+Angle(0,0,vel:Dot(ang:Right())*9)
                local wep = ply:GetActiveWeapon() if IsValid(wep) and IsValid(ply) then local dr = wep:GetNextPrimaryFire() - CurTime() if dr >= 0.03 then ang.p = ang.p - (dr)*36 ang.r = ang.r + (dr)*69*math.sin(CurTime()) end end
                ang=LerpAngle(spd*0.08+0.06,da,ang+Angle(0,0,lo)) da = ang dx=dx+spd*0.016 ang=ang+Angle(Noise(dx,1),Noise(dx,2),Noise(dx,3))*spd*1.5 ang=ang+Angle(Noise(CurTime(),4),Noise(CurTime(),5),Noise(CurTime(),6))*1.5
                spd=spd+3 dt=dt+(Noise(CurTime())+1)/60 ang=ang+Angle(Noise(dt,1),Noise(dt,2),Noise(dt,3))*spd/8 dt=dt+(Noise(CurTime())+1)/90 ang=ang+Angle(Noise(dt,4),Noise(dt,5),Noise(dt,6))*spd/6 return {origin=pos,angles=ang,fov=100} end end) end
            end

        if GetConVar("itr_duck"):GetBool() then
            hook.Add("PlayerSpawn","ItR_Duck1",function(ply) ply:ConCommand("-duck") end)
            hook.Add("PlayerLeaveVehicle","ItR_Duck2",function(ply) ply:ConCommand("-duck") end)
            hook.Add("PlayerEnteredVehicle","ItR_Duck3",function(ply) ply:ConCommand("-duck") end)
            hook.Add("PlayerBindPress","ItR_Duck4",function(ply,bind) if string.find(bind,"+duck") then
            if (ply:Crouching() == false) and !ply:InVehicle() then ply:ConCommand("+duck") else ply:ConCommand("-duck") end end end)
            end

        if GetConVar("itr_fly"):GetBool() then
            hook.Add("Move", "ItR_Fly", function(ply, mv) if ply:GetMoveType() == MOVETYPE_NOCLIP then
                local vel = Vector(0, 0, 0) local ang = mv:GetMoveAngles() local horizontal = Angle(0, ang.y, 0):Forward() local right = Angle(0, ang.y, 0):Right()
                if mv:KeyDown(IN_JUMP) then vel = vel + Vector(0, 0, 1) end if mv:KeyDown(IN_DUCK) then vel = vel - Vector(0, 0, 1) end
                if mv:KeyDown(IN_FORWARD) then vel = vel + horizontal end if mv:KeyDown(IN_BACK) then vel = vel - horizontal end
                if mv:KeyDown(IN_MOVERIGHT) then vel = vel + right end if mv:KeyDown(IN_MOVELEFT) then vel = vel - right end
                vel = vel:GetNormalized() * (mv:KeyDown(IN_SPEED) and 99 or 9.9)
                mv:SetOrigin(mv:GetOrigin() + vel) mv:SetVelocity(Vector(0,0,0))
                return true end end)
            end

        if GetConVar("itr_flash"):GetBool() then
            if SERVER then
            util.AddNetworkString("ItR_Flash")
            hook.Add("EntityFireBullets", "ItR_Flash", function(ent, data)
                local dPos = data.Src + data.Dir * 29.99 net.Start("ItR_Flash")
                net.WriteVector(dPos) net.Broadcast() end)
            else net.Receive("ItR_Flash", function()
                    local dlight = DynamicLight(CurTime())
                    dlight.pos = net.ReadVector()
                    dlight.brightness = 0.5
                    dlight.decay = 1024
                    dlight.size = 512
                    dlight.r = 255
                    dlight.g = 240
                    dlight.b = 180
                    dlight.dietime = CurTime() + 0.03 end) end
            end