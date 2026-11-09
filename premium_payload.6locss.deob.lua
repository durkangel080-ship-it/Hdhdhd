-- Recovery status: partial
-- Statically recovered 147 functions from 1 VM layer(s). Original names and full behavioral equivalence are not guaranteed; inspect recovery warnings.
local alternateValue = ({ ... })[3]
local vdPremiumHooks = type(alternateValue) == "table" and alternateValue or {}

if type(alternateValue) ~= "table" then
  local g = _G
  g.VD_PremiumHooks = _G.VD_PremiumHooks or {}
  vdPremiumHooks = _G.VD_PremiumHooks
end

_G.VD_RemotePayloadLoaded = true
_G.VD_IsPremium = true

function vdPremiumHooks.RevolverSilentAim(object)
  local players = game:GetService("Players")
  local localPlayer = players.LocalPlayer
  local currentCamera = workspace.CurrentCamera
  local enabled = not currentCamera or not localPlayer
  local fovRadius, getNetworkPing

  if enabled then
    return
  else
    local objectValue = object[1]

    local position = typeof(objectValue) == "Instance" and objectValue:IsA("BasePart")
        and objectValue.Position
      or nil

    if not position then
      local character = localPlayer.Character
      local head = character and character:FindFirstChild("Head")
      position = head and head.Position
    end

    if not position then
      return
    else
      local vdSettings = _G.VD_Settings or {}
      fovRadius = vdSettings.RevolverSilentAim and vdSettings.RevolverSilentAim.FOVRadius or 200
      local number = currentCamera.ViewportSize / 2
      local priority = vdSettings.RevolverSilentAim and vdSettings.RevolverSilentAim.Priority
      local objectResult = {}
      local priorityValue = priority or "Nearest"
      local part = nil

      local target = vdSettings.RevolverSilentAim and vdSettings.RevolverSilentAim.Target
        or "All"

      local targetPart = vdSettings.RevolverAimbot and vdSettings.RevolverAimbot.TargetPart
        or "UpperTorso"

      for index, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
          local role = player:GetAttribute("Role")

          local name = role
          name = role or player.Team and player.Team.Name or ""

          if not player:GetAttribute("Role") then
            local backpack = player:FindFirstChild("Backpack")
            local character = player.Character

            if backpack and backpack:FindFirstChild("Knife")
              or character and character:FindFirstChild("Knife") then
              name = "Murderer"
            elseif backpack
                and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver"))
              or character
                and (character:FindFirstChild("Gun") or character:FindFirstChild("Revolver")) then
              name = "Sheriff"
            else
              name = "Innocent"
            end
          end

          local enabledValue = false

          if target == "All" or target == "Both Teams" then
            enabledValue = true
          elseif target == "Innocents"
            and (name == "Innocent" or name == "Innocents" or name == "Survivors") then
            enabledValue = true
          elseif (target == "Murder" or target == "Murderer" or target == "Killer")
            and (name == "Murderer" or name == "Murder" or name == "Killer") then
            enabledValue = true
          elseif target == "Sheriff" and name == "Sheriff" then
            enabledValue = true
          elseif target == "Survivors" and name == "Survivors" then
            enabledValue = true
          elseif target == "Killer" and name == "Killer" then
            enabledValue = true
          end

          if enabledValue then
            local character = player.Character

            local findFirstChild = character
              and (character:FindFirstChild(targetPart)
                or character:FindFirstChild("HumanoidRootPart"))

            local humanoid = character
            humanoid = character and character:FindFirstChild("Humanoid")

            if findFirstChild and humanoid and humanoid.Health > 0 then
              local currentCameraResult, enabledResult = currentCamera:WorldToViewportPoint(findFirstChild.Position)

              if enabledResult then
                local magnitude = (Vector2.new(currentCameraResult.X, currentCameraResult.Y)
                  - number).Magnitude

                if magnitude <= fovRadius then
                  table.insert(objectResult, {
                    part = findFirstChild,
                    dist = magnitude,
                    health = humanoid.Health,
                    maxHealth = humanoid.MaxHealth or 100,
                  })
                end
              end
            end
          end
        end
      end

      if #objectResult > 0 then
        if priorityValue == "Furthest" then
          table.sort(objectResult, function(alternateObject, fifthObject)
            if math.abs(alternateObject.dist - fifthObject.dist) > 0.01 then
              return alternateObject.dist > fifthObject.dist
            end

            return alternateObject.health < fifthObject.health
          end)
        elseif priorityValue == "Injured" then
          table.sort(objectResult, function(alternateObject, fifthObject)
            if math.abs(alternateObject.health - fifthObject.health) > 0.01 then
              return alternateObject.health < fifthObject.health
            end

            return alternateObject.dist < fifthObject.dist
          end)
        elseif priorityValue == "Healed" then
          table.sort(objectResult, function(alternateObject, fifthObject)
            if math.abs(alternateObject.health - fifthObject.health) > 0.01 then
              return alternateObject.health > fifthObject.health
            end

            return alternateObject.dist < fifthObject.dist
          end)
        elseif priorityValue == "NearestInjured" then
          table.sort(objectResult, function(alternateObject, fifthObject)
            local numberValue = 0.5 * (alternateObject.dist / fovRadius)
              + 0.5 * (alternateObject.health / math.max(alternateObject.maxHealth, 1))

            local numberResult = 0.5 * (fifthObject.dist / fovRadius)
              + 0.5 * (fifthObject.health / math.max(fifthObject.maxHealth, 1))

            if math.abs(numberValue - numberResult) > 0.001 then
              return numberValue < numberResult
            end

            return alternateObject.dist < fifthObject.dist
          end)
        elseif priorityValue == "NearestHealed" then
          table.sort(objectResult, function(alternateObject, fifthObject)
            local numberValue = 0.5 * (alternateObject.dist / fovRadius)
              + 0.5 * (1 - alternateObject.health / math.max(alternateObject.maxHealth, 1))

            local numberResult = 0.5 * (fifthObject.dist / fovRadius)
              + 0.5 * (1 - fifthObject.health / math.max(fifthObject.maxHealth, 1))

            if math.abs(numberValue - numberResult) > 0.001 then
              return numberValue < numberResult
            end

            return alternateObject.dist < fifthObject.dist
          end)
        else
          table.sort(objectResult, function(alternateObject, fifthObject)
            return alternateObject.dist < fifthObject.dist
          end)
        end

        part = objectResult[1].part
      end

      if part then
        local vector = Vector3.new(0, 0, 0)
        local positionValue = part.Position
        getNetworkPing = 0.06
        pcall(function() getNetworkPing = localPlayer:GetNetworkPing() end)
        local character = localPlayer.Character

        local humanoidRootPart = character
        humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

        local numberValue = position
          - (humanoidRootPart
                and (humanoidRootPart.AssemblyLinearVelocity or humanoidRootPart.Velocity)
              or Vector3.new(0, 0, 0))
            * (getNetworkPing / 2)

        local enabledValue = true

        if vdSettings.RevolverAimbot and vdSettings.RevolverAimbot.PredictionEnabled == false then
          enabledValue = false
        end

        if enabledValue then
          local bulletVelocity = vdSettings.RevolverAimbot
              and vdSettings.RevolverAimbot.BulletVelocity
            or 800

          positionValue = positionValue
            + vector
              * (0.1 + getNetworkPing / 2
                + (positionValue - numberValue).Magnitude / bulletVelocity)
        end

        local unit = (positionValue - numberValue).Unit

        if unit.X == unit.X then
          object[2] = unit
        end
      end

      return
    end
  end
end

function vdPremiumHooks.SpearSilentAim(object)
  local players = game:GetService("Players")
  local localPlayer = players.LocalPlayer
  local currentCamera = workspace.CurrentCamera
  local enabled = not currentCamera or not localPlayer
  local fovRadius, part, vector, getPlayerFromCharacter, g, vectorValue

  if enabled then
    return
  else
    local position = object[3]

    if typeof(position) ~= "Vector3" then
      position = currentCamera and currentCamera.CFrame.Position
        or localPlayer.Character and localPlayer.Character:FindFirstChild("Head")
          and localPlayer.Character.Head.Position
    end

    if typeof(position) ~= "Vector3" then
      return
    else
      local vdSettings = _G.VD_Settings or {}
      fovRadius = vdSettings.SpearSilentAim and vdSettings.SpearSilentAim.FOVRadius or 240
      local number = currentCamera.ViewportSize / 2

      local priority = vdSettings.SpearSilentAim and vdSettings.SpearSilentAim.Priority
        or "Nearest"

      local objectValue = {}
      local getPlayers = players.GetPlayers
      part = nil

      for index, player in ipairs(getPlayers(players)) do
        if player ~= localPlayer then
          local character = player.Character

          local humanoidRootPart = character
          humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

          local humanoid = character
          humanoid = character and character:FindFirstChild("Humanoid")

          if humanoidRootPart and humanoid and humanoid.Health > 0 then
            local currentCameraResult, enabledValue = currentCamera:WorldToViewportPoint(humanoidRootPart.Position)

            if enabledValue then
              local magnitude = (Vector2.new(currentCameraResult.X, currentCameraResult.Y)
                - number).Magnitude

              if magnitude <= fovRadius then
                table.insert(objectValue, {
                  part = humanoidRootPart,
                  dist = magnitude,
                  health = humanoid.Health,
                  maxHealth = humanoid.MaxHealth or 100,
                })
              end
            end
          end
        end
      end

      if #objectValue > 0 then
        if priority == "Furthest" then
          table.sort(objectValue, function(objectResult, alternateObject)
            if math.abs(objectResult.dist - alternateObject.dist) > 0.01 then
              return objectResult.dist > alternateObject.dist
            end

            return objectResult.health < alternateObject.health
          end)
        elseif priority == "Injured" then
          table.sort(objectValue, function(objectResult, alternateObject)
            if math.abs(objectResult.health - alternateObject.health) > 0.01 then
              return objectResult.health < alternateObject.health
            end

            return objectResult.dist < alternateObject.dist
          end)
        elseif priority == "Healed" then
          table.sort(objectValue, function(objectResult, alternateObject)
            if math.abs(objectResult.health - alternateObject.health) > 0.01 then
              return objectResult.health > alternateObject.health
            end

            return objectResult.dist < alternateObject.dist
          end)
        elseif priority == "NearestInjured" then
          table.sort(objectValue, function(objectResult, alternateObject)
            local numberValue = 0.5 * (objectResult.dist / fovRadius)
              + 0.5 * (objectResult.health / math.max(objectResult.maxHealth, 1))

            local numberResult = 0.5 * (alternateObject.dist / fovRadius)
              + 0.5 * (alternateObject.health / math.max(alternateObject.maxHealth, 1))

            if math.abs(numberValue - numberResult) > 0.001 then
              return numberValue < numberResult
            end

            return objectResult.dist < alternateObject.dist
          end)
        elseif priority == "NearestHealed" then
          table.sort(objectValue, function(objectResult, alternateObject)
            local numberValue = 0.5 * (objectResult.dist / fovRadius)
              + 0.5 * (1 - objectResult.health / math.max(objectResult.maxHealth, 1))

            local numberResult = 0.5 * (alternateObject.dist / fovRadius)
              + 0.5 * (1 - alternateObject.health / math.max(alternateObject.maxHealth, 1))

            if math.abs(numberValue - numberResult) > 0.001 then
              return numberValue < numberResult
            end

            return objectResult.dist < alternateObject.dist
          end)
        else
          table.sort(objectValue, function(objectResult, alternateObject)
            return objectResult.dist < alternateObject.dist
          end)
        end

        part = objectValue[1].part
      end

      if part then
        vector = Vector3.new(0, 0, 0)

        pcall(function()
          vector = part.AssemblyLinearVelocity or part.Velocity or Vector3.new(0, 0, 0)
        end)

        getPlayerFromCharacter = players:GetPlayerFromCharacter(part.Parent) or part.Parent
          or part

        g = vector

        if _G.VD_GetSmoothedVelocity then
          pcall(function()
            g = _G.VD_GetSmoothedVelocity(getPlayerFromCharacter, vector, part)
          end)
        end

        vectorValue = Vector3.new(0, 0, 0)

        pcall(function()
          local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")

          if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            vectorValue = Vector3.new(0, -workspace.Gravity, 0)
          end
        end)

        local positionValue = part.Position

        if g.Magnitude <= 0.1 then
          g = Vector3.new(0, 0, 0)
          vectorValue = Vector3.new(0, 0, 0)
        end

        local fifthValue = object[2] or 142.5
        local character = localPlayer.Character

        local vdSpecialSpearGravity = character and character:GetAttribute("special") == true
            and (_G.VD_SpecialSpearGravity or 98.1)
          or _G.VD_NormalSpearGravity
          or 98.1

        if _G.VD_SolveProjectileAim then
          local gValue = _G.VD_SolveProjectileAim(
            position, positionValue, g, vectorValue, fifthValue, vdSpecialSpearGravity
          )

          if gValue then
            object[1] = gValue
          end
        end
      end

      return
    end
  end
end

function vdPremiumHooks.AntiWiggle()
  local players = game:GetService("Players")
  local localPlayer = players.LocalPlayer

  if not localPlayer then
    return
  end

  if localPlayer:GetAttribute("IsCarrying") == true
    or localPlayer.Character and localPlayer.Character:GetAttribute("IsCarrying") == true then
    local player = nil

    for index, playerValue in ipairs(players:GetPlayers()) do
      if playerValue ~= localPlayer then
        local character = playerValue.Character

        if playerValue:GetAttribute("IsCarried") == true
          or character and character:GetAttribute("IsCarried") == true then
          player = playerValue
          break
        end
      end
    end

    if player then
      local character = player.Character

      local remainingCarryTime = player:GetAttribute("RemainingCarryTime")
        or character and character:GetAttribute("RemainingCarryTime")
        or localPlayer:GetAttribute("RemainingCarryTime")
        or localPlayer.Character and localPlayer.Character:GetAttribute("RemainingCarryTime")

      if remainingCarryTime and type(remainingCarryTime) == "number" and remainingCarryTime <= 1 then
        local dropSurvivorEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Carry"):WaitForChild("DropSurvivorEvent")

        if dropSurvivorEvent then
          dropSurvivorEvent:FireServer()
        end
      end
    end
  end
end

function vdPremiumHooks.InstantBandage(player, callback)
  local character = player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local bandage, fire

  if not humanoid then
    if callback then
      callback("Instant Bandage", "Character humanoid not found!", "error")
    end

    return
  elseif humanoid.Health >= humanoid.MaxHealth then
    if callback then
      callback("Instant Bandage", "You are already at full health!", "warning")
    end

    return
  else
    local bandageValue = character:FindFirstChild("Bandage")
      or player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Bandage")

    if not bandageValue then
      if callback then
        callback("Instant Bandage", "No bandage tool in Backpack or equipped!", "error")
      end

      return
    end

    if bandageValue.Parent == player:FindFirstChild("Backpack") then
      pcall(function() humanoid:EquipTool(bandageValue) end)
      task.wait(0.1)
    end

    if bandageValue.Parent ~= character then
      if callback then
        callback("Instant Bandage", "Failed to equip bandage tool!", "error")
      end

      return
    else
      local rightArm = bandageValue:FindFirstChild("Right Arm")
      bandage = rightArm and rightArm:FindFirstChild("Bandage")

      if not bandage then
        bandage = bandageValue:FindFirstChild("Bandage", true)
      end

      if not bandage then
        if callback then
          callback("Instant Bandage", "Bandage part not found inside tool!", "error")
        end

        return
      else
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")

        local items = remotes
        items = remotes and remotes:FindFirstChild("Items")

        local bandageResult = items
        bandageResult = items and items:FindFirstChild("Bandage")

        fire = bandageResult and bandageResult:FindFirstChild("Fire")

        if not fire then
          if callback then
            callback(
              "Instant Bandage", "Bandage remote not found in ReplicatedStorage!", "error"
            )
          end

          return
        end

        if callback then
          callback("Instant Bandage", "Spamming bandage...", "success")
        end

        task.spawn(function()
          local number = tick()

          while humanoid.Health < humanoid.MaxHealth and bandageValue.Parent == character
            and humanoid.Health > 0 and tick() - number < 8 do
            pcall(function()
              fire:FireServer(true, bandage)
              fire:FireServer(false, bandage)
            end)

            task.wait(0.01)
          end

          if callback then
            if humanoid.Health >= humanoid.MaxHealth then
              callback("Instant Bandage", "Healed to full health!", "success")
            else
              callback("Instant Bandage", "Stopped healing.", "info")
            end
          end
        end)

        return
      end
    end
  end
end

function vdPremiumHooks.BlockVaults(fifthValue, callback)
  pcall(function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local window = remotes and remotes:FindFirstChild("Window")
    local vaultEvent = window and window:FindFirstChild("VaultEvent")

    if vaultEvent then
      for index, object in ipairs(fifthValue or {}) do
        if object and object.Parent then
          for indexValue, objectValue in ipairs(object:GetDescendants()) do
            if objectValue.Name == "VaultTrigger" then
              vaultEvent:FireServer(objectValue, true)
            end
          end
        end
      end

      if callback then
        callback("Block Vaults", "Vaults blocked!", "success")
      end
    elseif callback then
      callback("Block Vaults", "VaultEvent remote not found!", "error")
    end
  end)
end

function vdPremiumHooks.BlockPallets(fifthValue, sixthValue)
end

function vdPremiumHooks.UnlockVaults(callback)
  pcall(function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    remotes = remotes and remotes:FindFirstChild("Window")
    remotes = remotes and remotes:FindFirstChild("VaultCompleteEvent")

    if remotes then
      local count = 0

      for index, fifthValue in ipairs((workspace:FindFirstChild("Map") or workspace):GetDescendants()) do
        local object = fifthValue
        local lowercase = object.Name:lower()

        if lowercase:find("vault") and (lowercase:find("trigger") or lowercase:find("point")) then
          pcall(function() remotes:FireServer(object, false) end)
          count = count + 1
        end
      end

      if callback then
        if count > 0 then
          callback("Unlock Vaults", "Unlocked " .. tostring(count) .. " vaults!", "success")
        else
          callback("Unlock Vaults", "No VaultTriggers/Points found!", "warning")
        end
      end
    elseif callback then
      callback("Unlock Vaults", "Remote not found!", "error")
    end
  end)
end

function vdPremiumHooks.UnlockPallets(fifthValue, sixthValue)
end

function vdPremiumHooks.CancelGen(player, fifthValue, callback)
  if callback then
    callback("Generator Buff", "Attempting to buff generator...", "info")
  end

  task.spawn(function()
    local success, sixthValue = pcall(function()
      local character = player.Character
      local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

      if not humanoidRootPart then
        if callback then
          callback("Generator Buff", "Character HumanoidRootPart not found!", "error")
        end

        return
      else
        local function callbackValue(object)
          if object:IsA("Model") then
            return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
          end

          return object:FindFirstChildWhichIsA("BasePart")
        end

        local entries = {}
        local map = workspace:FindFirstChild("Map")
        local entriesValue = {}

        if map then
          local generators = map:FindFirstChild("Generators")
          local gens = map:FindFirstChild("Gens")

          if generators then
            table.insert(entriesValue, generators)
          end

          if gens then
            table.insert(entriesValue, gens)
          end
        end

        for index, object in ipairs(entriesValue) do
          for indexValue, objectValue in ipairs(object:GetChildren()) do
            local matches = objectValue.Name == "Generator"
            local matchesValue = matches

            if not matches then
              local name = objectValue.Name
              matchesValue = string.find(name:lower(), "generator")
            end

            if matchesValue then
              table.insert(entries, objectValue)
            end
          end
        end

        if #entries == 0 and fifthValue then
          for index, object in ipairs(fifthValue) do
            if object and object.Parent then
              table.insert(entries, object)
            end
          end
        end

        if #entries == 0 then
          for index, object in ipairs(workspace:GetDescendants()) do
            if object.Name == "Generator" then
              table.insert(entries, object)
            end
          end
        end

        if #entries == 0 then
          if callback then
            callback("Generator Buff", "No generators found in map!", "error")
          end

          return
        else
          local object = nil
          local huge = math.huge

          for index, seventhValue in ipairs(entries) do
            local objectValue = callbackValue(seventhValue)

            if objectValue then
              local magnitude = (objectValue.Position - humanoidRootPart.Position).Magnitude

              if magnitude < huge then
                object = seventhValue
                huge = magnitude
              end
            end
          end

          if not object or huge > 15 then
            local stringValue = object and string.format("%.1f studs", huge) or "N/A"

            if callback then
              callback(
                "Generator Buff", "No generator within 15 studs! (" .. stringValue .. ")",
                "error"
              )
            end

            return
          else
            local objectValue = {}

            for index, objectResult in ipairs(object:GetChildren()) do
              local name = objectResult.Name

              if string.find(name:lower(), "generatorpoint") then
                table.insert(objectValue, objectResult)
              end
            end

            table.sort(objectValue, function(objectResult, alternateObject)
              return objectResult.Name < alternateObject.Name
            end)

            if #objectValue == 0 then
              if callback then
                callback("Generator Buff", "No generator points resolved!", "error")
              end

              return
            else
              local replicatedStorage = game:GetService("ReplicatedStorage")
              local remotes = replicatedStorage:FindFirstChild("Remotes")

              local generator = remotes
              generator = remotes and remotes:FindFirstChild("Generator")

              local repairEvent = generator
              repairEvent = generator and generator:FindFirstChild("RepairEvent")

              if not repairEvent then
                repairEvent = replicatedStorage:FindFirstChild("RepairEvent", true)
              end

              if not repairEvent then
                if callback then
                  callback("Generator Buff", "RepairEvent remote not found!", "error")
                end

                return
              else
                local index = #objectValue

                if index == 2 then
                  local seventhValue = objectValue[1]
                  repairEvent:FireServer(objectValue[2], true)
                  task.wait(0.2)
                  repairEvent:FireServer(seventhValue, true)
                  task.wait(0.2)
                  repairEvent:FireServer(seventhValue, false)
                else
                  local seventhValue = objectValue[index]
                  local eighthValue = index - 1
                  local count = 0

                  while true do
                    count = 1 + count

                    if not (count <= eighthValue) then
                      break
                    end

                    local countValue = count
                    repairEvent:FireServer(objectValue[countValue], true)
                    task.wait(0.2)
                    repairEvent:FireServer(seventhValue, true)
                    task.wait(0.2)
                    repairEvent:FireServer(seventhValue, false)

                    if countValue < index - 1 then
                      task.wait(0.2)
                    end
                  end
                end

                if callback then
                  callback("Generator Buff", "Successfully applied generator buff!", "success")
                end

                return
              end
            end
          end
        end
      end
    end)

    if not success and callback then
      callback("Generator Buff", "Critical Error: " .. tostring(sixthValue), "error")
    end
  end)
end

function vdPremiumHooks.AlwaysFastVault_OnAnim(object, objectValue, objectResult)
  if not (objectResult and objectResult.AlwaysFastVault) then
    return
  else
    local lowercase = tostring(object.Animation and object.Animation.AnimationId or ""):lower()
    local lowercaseValue = (object.Name or ""):lower()

    if lowercase:find("126081405469607") or lowercaseValue:find("walkingvault") then
      pcall(function() object:Stop(0) end)

      if objectValue then
        pcall(function() objectValue:Play(0.02) end)
      end
    end

    return
  end
end

function vdPremiumHooks.AlwaysFastVault_OnInput(object, player, callback, objectValue)
  if not (objectValue and objectValue.AlwaysFastVault) then
    return
  end

  local unit, character

  if object.KeyCode == Enum.KeyCode.E or object.KeyCode == Enum.KeyCode.Space then
    character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

    if humanoidRootPart and callback then
      local objectResult = callback(humanoidRootPart.Position)

      if objectResult then
        local alternateObject = objectResult.Position - humanoidRootPart.Position
        local vector = Vector3.new(alternateObject.X, 0, alternateObject.Z)

        if vector.Magnitude > 0.05 then
          unit = vector.Unit
        else
          local lookVector = humanoidRootPart.CFrame.LookVector
          unit = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        end

        local dot = humanoidRootPart.CFrame.LookVector:Dot(unit)

        if not (humanoidRootPart.AssemblyLinearVelocity.Magnitude >= 13 and dot >= 0.7) then
          pcall(function()
            character:SetAttribute("Sprinting", true)
            character:SetAttribute("IsRunning", true)
          end)

          humanoidRootPart.CFrame = CFrame.new(
            humanoidRootPart.Position, humanoidRootPart.Position + unit
          )

          humanoidRootPart.AssemblyLinearVelocity = unit * 22
        end
      end
    end
  end
end

function vdPremiumHooks.AlwaysFastVault_OnNamecall(object, fifthValue, objectValue, player, objectResult, alternateObject, fifthObject)
  if not (fifthObject and fifthObject.AlwaysFastVault) then
    return
  end

  local character

  if (fifthValue == "FireServer" or fifthValue == "InvokeServer")
    and typeof(object) == "Instance" then
    if object.Name == "VaultEvent" then
      if objectValue[2] == false then
        objectValue[2] = true
        character = player.Character

        if character then
          pcall(function()
            character:SetAttribute("Sprinting", true)
            character:SetAttribute("IsRunning", true)
          end)
        end

        if objectResult and character then
          pcall(function() objectResult:FireServer(character) end)
        end

        if alternateObject then
          pcall(function() alternateObject:FireServer() end)
        end
      end
    end
  end
end

function vdPremiumHooks.CustomGenSound(object, fifthValue, sixthValue)
  if not object or not object:IsA("Model") then
    return
  else
    local function callback(seventhValue)
      if not seventhValue or seventhValue == "" then
        return "rbxassetid://124429695332529"
      elseif type(seventhValue) == "number" then
        return "rbxassetid://" .. tostring(seventhValue)
      else
        local substituteText = tostring(seventhValue):gsub("%s+", "")

        if substituteText:find("^rbxassetid://") or substituteText:find("^http")
          or substituteText:find("^assetgame") then
          return substituteText
        else
          local d = substituteText:match("%d+")

          if d then
            return "rbxassetid://" .. d
          end

          return substituteText
        end
      end
    end

    local soundId = callback(fifthValue)
    local volume = sixthValue or 1
    local hitBox = object:FindFirstChild("HitBox") or object:FindFirstChild("Hitbox")

    if hitBox then
      local done = hitBox:FindFirstChild("Done")

      if done and done:IsA("Sound") then
        if done.SoundId ~= soundId then
          done.SoundId = soundId
        end

        done.Volume = volume
      end
    end

    return
  end
end

function vdPremiumHooks.AutoFleeKiller(fifthValue, object, number, sixthValue, callback, callbackValue, callbackResult, alternateCallback, fifthCallback)
  if not fifthValue or not object or not number then
    return false
  else
    local enabled = nil
    local magnitude = -1

    for index, objectValue in ipairs(sixthValue or {}) do
      if objectValue and objectValue.Parent
        and not (callbackValue and callbackValue(objectValue))
        and not (callbackResult and callbackResult(objectValue)) then
        local objectResult = callback
        objectResult = callback and callback(objectValue)

        if objectResult then
          local magnitudeValue = (objectResult.Position - number).Magnitude

          if magnitudeValue > magnitude then
            if alternateCallback and alternateCallback(objectValue) then
              magnitude = magnitudeValue
              enabled = objectValue
            end
          end
        end
      end
    end

    if enabled then
      local objectValue = alternateCallback
      objectValue = alternateCallback and alternateCallback(enabled)

      if objectValue then
        object.CFrame = objectValue.CFrame + Vector3.new(0, 1.5, 0)

        if fifthCallback then
          fifthCallback("Auto Flee Killer", "Fled from killer to a safe generator!", "info")
        end

        return true
      end

      return false
    end

    return false
  end
end

function vdPremiumHooks.StalkerDodge(object, objectValue, fifthValue, sixthValue)
  if not object or not objectValue then
    return false
  else
    local success, seventhValue = pcall(function()
      return (object.Position - objectValue.Position).Magnitude
    end)

    if success and seventhValue <= (fifthValue or 15) then
      return true
    end

    return false
  end
end

function vdPremiumHooks.InstantEscape(object, callback)
  if not object then
    return
  else
    local objectValue = nil
    local huge = math.huge

    for index, objectResult in ipairs(workspace:GetDescendants()) do
      if objectResult:IsA("BasePart")
        and (objectResult.Name == "Fininshline" or objectResult.Name == "Finishline"
          or objectResult.Name:lower():find("finishline")
          or objectResult.Name:lower():find("fininshline")) then
        local magnitude = (objectResult.Position - object.Position).Magnitude

        if magnitude < huge then
          huge = magnitude
          objectValue = objectResult
        end
      end
    end

    if objectValue then
      if _G.VD_StopAllInteractions then
        task.wait(0.15)
      end

      object.CFrame = objectValue.CFrame

      if callback then
        callback("Instant Escape", "Teleported to finish line!", "success")
      end
    elseif callback then
      callback("Escape Failed", "No Finish Line found on this map!", "error")
    end

    return
  end
end

function vdPremiumHooks.ManualSpoofGen(player, fifthValue, callback)
  local character = player and player.Character
  local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
  local callbackValue

  if not humanoidRootPart then
    if callback then
      callback("Manual Spoof", "Character HumanoidRootPart not found!", "error")
    end

    return
  else
    local function callbackResult(object)
      if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
      end

      return object:FindFirstChildWhichIsA("BasePart")
    end

    local entries = {}
    local map = workspace:FindFirstChild("Map")
    local entriesValue = {}

    if map then
      local generators = map:FindFirstChild("Generators")
      local gens = map:FindFirstChild("Gens")

      if generators then
        table.insert(entriesValue, generators)
      end

      if gens then
        table.insert(entriesValue, gens)
      end
    end

    for index, object in ipairs(entriesValue) do
      for indexValue, objectValue in ipairs(object:GetChildren()) do
        local matches = objectValue.Name == "Generator"
        local matchesValue = matches

        if not matches then
          local name = objectValue.Name
          matchesValue = string.find(name:lower(), "generator")
        end

        if matchesValue then
          table.insert(entries, objectValue)
        end
      end
    end

    if #entries == 0 and type(fifthValue) == "table" then
      for index, object in ipairs(fifthValue) do
        if object and object.Parent then
          table.insert(entries, object)
        end
      end
    end

    if #entries == 0 then
      for index, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") and (object.Name == "Generator" or object.Name:find("Generator")) then
          table.insert(entries, object)
        end
      end
    end

    if #entries == 0 then
      if callback then
        callback("Manual Spoof", "No generators found in map!", "error")
      end

      return
    else
      local object = nil
      local huge = math.huge

      for index, sixthValue in ipairs(entries) do
        local objectValue = callbackResult(sixthValue)

        if objectValue then
          local magnitude = (objectValue.Position - humanoidRootPart.Position).Magnitude

          if magnitude < huge then
            object = sixthValue
            huge = magnitude
          end
        end
      end

      if not object or huge > 35 then
        local stringValue = object and string.format("%.1f studs", huge) or "N/A"

        if callback then
          callback(
            "Manual Spoof", "No generator within 35 studs! (" .. stringValue .. ")", "error"
          )
        end

        return
      else
        local objectValue = {}

        for index, objectResult in ipairs(object:GetChildren()) do
          local name = objectResult.Name
          local stringValue = string.find(name:lower(), "generatorpoint")
          local stringResult = stringValue

          if not stringValue then
            local nameValue = objectResult.Name
            stringResult = string.find(nameValue:lower(), "point")
          end

          if stringResult then
            table.insert(objectValue, objectResult)
          end
        end

        function callbackValue(objectResult)
          if objectResult:IsA("BasePart") then
            return objectResult.Position
          elseif objectResult:IsA("Model") then
            return objectResult:GetPivot().Position
          else
            local basePart = objectResult:FindFirstChildWhichIsA("BasePart")

            if basePart then
              return basePart.Position
            end

            return objectResult.Parent and objectResult.Parent:IsA("Model")
                and objectResult.Parent:GetPivot().Position
              or Vector3.zero
          end
        end

        table.sort(objectValue, function(sixthValue, seventhValue)
          return (callbackValue(sixthValue) - humanoidRootPart.Position).Magnitude
            < (callbackValue(seventhValue) - humanoidRootPart.Position).Magnitude
        end)

        local replicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = replicatedStorage:FindFirstChild("Remotes")

        local generator = remotes
        generator = remotes and remotes:FindFirstChild("Generator")

        local repairEvent = generator
        repairEvent = generator and generator:FindFirstChild("RepairEvent")

        if not repairEvent then
          repairEvent = replicatedStorage:FindFirstChild("RepairEvent", true)
        end

        if not repairEvent then
          for index, objectResult in ipairs(replicatedStorage:GetDescendants()) do
            if objectResult:IsA("RemoteEvent")
              and (objectResult.Name == "RepairEvent" or objectResult.Name == "Repair") then
              repairEvent = objectResult
              break
            end
          end
        end

        if repairEvent and #objectValue > 0 then
          local sixthValue = objectValue[1]
          local matches = #objectValue > 1 and objectValue[#objectValue] or nil
          repairEvent:FireServer(sixthValue, true)
          task.wait(0.1)
          repairEvent:FireServer(sixthValue, true)
          task.wait(0.1)

          if matches and matches ~= sixthValue then
            repairEvent:FireServer(matches, false)
          end

          if callback then
            callback("Manual Spoof", "Successfully spoofed +1 player on generator!", "success")
          end
        elseif callback then
          callback("Manual Spoof", "Could not find generator repair event/points!", "error")
        end

        return
      end
    end
  end
end

function vdPremiumHooks.NoSkillChecks(object, fifthValue)
  if not object or not fifthValue then
    return
  end

  for index, sixthValue in ipairs(object:GetChildren()) do
    local objectValue = sixthValue

    if objectValue.Name:lower():find("skillcheck") then
      if not table.find(fifthValue, objectValue) then
        table.insert(fifthValue, objectValue)
      end

      pcall(function() objectValue.Parent = nil end)
    end
  end
end

function vdPremiumHooks.RunSpearAimbot(object)
  local char, camera, userInputService, players, settings, spearChargeStart, specialSpearSpeed,
    normalSpearSpeed, specialSpearGravity, normalSpearGravity, getSmoothedVelocity,
    solveProjectileAim, isMouseButtonPressed, key, root

  if not object then
    return
  else
    char = object.char
    local localPlayer = object.localPlayer
    camera = object.camera
    local isMobile = object.isMobile
    userInputService = object.UserInputService
    players = object.Players
    settings = object.Settings
    spearChargeStart = object.spearChargeStart
    specialSpearSpeed = object.specialSpearSpeed
    normalSpearSpeed = object.normalSpearSpeed
    specialSpearGravity = object.specialSpearGravity
    normalSpearGravity = object.normalSpearGravity
    local sortCandidatesByPriority = object.sortCandidatesByPriority
    getSmoothedVelocity = object.getSmoothedVelocity
    solveProjectileAim = object.solveProjectileAim
    local getTarget = object.getTarget
    local setTarget = object.setTarget

    if not settings or not settings.SpearAimbot or not settings.SpearAimbot.Enabled then
      if setTarget then
        setTarget(nil)
      end

      return
    else
      local charValue = char
      local enabled = false

      if char then
        charValue = char:GetAttribute("spearmode") == true
      end

      if charValue then
        enabled = true
      elseif localPlayer and localPlayer:GetAttribute("spearmode") == true then
        enabled = true
      end

      if not enabled then
        if setTarget then
          setTarget(nil)
        end

        return
      end

      isMouseButtonPressed = false

      if isMobile then
        isMouseButtonPressed = true
      else
        key = settings.SpearAimbot.Key or "MouseButton2"

        if key == "MouseButton2" then
          isMouseButtonPressed = userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif key == "MouseButton1" then
          isMouseButtonPressed = userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        else
          pcall(function()
            isMouseButtonPressed = userInputService:IsKeyDown(Enum.KeyCode[key])
          end)
        end
      end

      if not isMouseButtonPressed then
        if setTarget then
          setTarget(nil)
        end

        return
      elseif not camera then
        return
      else
        local getMouseLocation = userInputService:GetMouseLocation()

        if isMobile then
          getMouseLocation = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        end

        local radius = settings.SpearAimbot.Radius or 150
        local priority = settings.SpearAimbot.Priority or "Nearest"
        root = getTarget and getTarget()

        if not root or not root.Parent or not root.Parent:FindFirstChildOfClass("Humanoid")
          or root.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 then
          local team = localPlayer and localPlayer.Team
          local entries = {}

          for index, player in ipairs(players:GetPlayers()) do
            if player ~= localPlayer and not (team and player.Team == team) then
              local character = player.Character

              local humanoid = character
              humanoid = character and character:FindFirstChildOfClass("Humanoid")

              local findFirstChild = character
              local targetPart = settings.SpearAimbot.TargetPart or "UpperTorso"

              if character then
                findFirstChild = character:FindFirstChild(targetPart)
                  or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
                  or character:FindFirstChild("HumanoidRootPart")
              end

              if character and humanoid and humanoid.Health > 0 and findFirstChild then
                local cameraResult, enabledValue = camera:WorldToViewportPoint(findFirstChild.Position)

                if enabledValue then
                  local magnitude = (Vector2.new(cameraResult.X, cameraResult.Y)
                    - getMouseLocation).Magnitude

                  if magnitude <= radius then
                    table.insert(entries, {
                      root = findFirstChild,
                      dist = magnitude,
                      health = humanoid.Health,
                      maxHealth = math.max(humanoid.MaxHealth, 1),
                    })
                  end
                end
              end
            end
          end

          local sortCandidatesByPriorityValue = sortCandidatesByPriority

          sortCandidatesByPriorityValue = sortCandidatesByPriority
            and sortCandidatesByPriority(entries, priority, radius)

          root = sortCandidatesByPriorityValue and sortCandidatesByPriorityValue.root or nil

          if setTarget then
            setTarget(root)
          end
        end

        if root and char then
          pcall(function()
            local parent = root.Parent

            local humanoidRootPart = parent:FindFirstChild("HumanoidRootPart")
              or parent.PrimaryPart or parent:FindFirstChild("Torso")
              or parent:FindFirstChild("UpperTorso")

            if humanoidRootPart then
              local head = char:FindFirstChild("Head")
                or char:FindFirstChild("HumanoidRootPart")

              local position = camera.CFrame.Position

              if head then
                position = head.CFrame:PointToWorldSpace((Vector3.new(1.35, 0.34, -2.51)))
              end

              local positionValue = root.Position
              local assemblyLinearVelocity = humanoidRootPart.AssemblyLinearVelocity
              local getPlayerFromCharacter = players:GetPlayerFromCharacter(parent)

              local getPlayerFromCharacterValue = getPlayerFromCharacter and getSmoothedVelocity and getSmoothedVelocity(
                getPlayerFromCharacter, assemblyLinearVelocity
              ) or assemblyLinearVelocity

              local fifthValue = positionValue + getPlayerFromCharacterValue * 0.09
              local vector = Vector3.new(0, 0, 0)
              local humanoid = parent:FindFirstChildOfClass("Humanoid")

              if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
                vector = Vector3.new(0, -workspace.Gravity, 0)
              end

              local matches = char:GetAttribute("special") == true
              local speed = settings.SpearAimbot.Speed or 150
              local gravity = settings.SpearAimbot.Gravity or 98
              local speedValue = speed
              local gravityValue = gravity

              if speed == 150 then
                speedValue = matches and specialSpearSpeed or normalSpearSpeed
              elseif matches then
                speedValue = speed * 1.1333333333333
              end

              if gravity == 98 then
                gravityValue = matches and specialSpearGravity or normalSpearGravity
              elseif matches then
                gravityValue = gravity
              end

              local number = tick() - (spearChargeStart or tick())
              local numberValue = speedValue * 0.7333

              local sixthValue = numberValue
                + (speedValue - numberValue) * math.clamp(number / 1, 0, 1)

              if solveProjectileAim then
                local solveProjectileAimResult, objectValue = solveProjectileAim(
                  position, fifthValue, getPlayerFromCharacterValue, vector, sixthValue,
                  gravityValue
                )

                local humanoidRootPartValue = char:FindFirstChild("HumanoidRootPart")

                if humanoidRootPartValue then
                  humanoidRootPartValue.CFrame = CFrame.new(humanoidRootPartValue.Position, (Vector3.new(
                    objectValue.X, humanoidRootPartValue.Position.Y, objectValue.Z
                  )))
                end

                local cframe = CFrame.lookAt(camera.CFrame.Position, position
                  + solveProjectileAimResult * (objectValue - position).Magnitude)

                local smoothness = settings.SpearAimbot.Smoothness or 0.05

                if smoothness <= 0 then
                  camera.CFrame = cframe
                else
                  camera.CFrame = camera.CFrame:Lerp(cframe, smoothness)
                end
              end
            end
          end)
        end

        return
      end
    end
  end
end

function vdPremiumHooks.SimulateParryAnimation(player, fifthValue)
  local character

  if not player then
    return
  else
    character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    if humanoid and animator then
      task.spawn(function()
        local text = "109133187196613"

        pcall(function()
          local findFirstChild = workspace:FindFirstChild(player.Name)

          local parryingDagger = findFirstChild
            and findFirstChild:FindFirstChild("Parrying Dagger")

          local main = parryingDagger and parryingDagger:FindFirstChild("Main")

          if main then
            local parry = main:FindFirstChild("parry")

            if parry and parry:IsA("Sound") and parry.SoundId == "rbxassetid://108343313427067" then
              text = "126894569253341"
            end

            local parried = main:FindFirstChild("parried")

            if parried and parried:IsA("Sound")
              and parried.SoundId == "rbxassetid://110870555206505" then
              text = "123307242865945"
            end
          end
        end)

        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. text

        local loadAnimation = animator:LoadAnimation(animation)
        local walkSpeed = humanoid.WalkSpeed
        local jumpPower = humanoid.JumpPower
        local jumpHeight = humanoid.JumpHeight

        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0

        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if humanoidRootPart then
          humanoidRootPart.Anchored = true
        end

        local getControls

        pcall(function()
          getControls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
          getControls:Disable()
        end)

        loadAnimation:Play()
        local enabled = false

        local connect

        connect = loadAnimation.Stopped:Connect(function()
          enabled = true

          if connect then
            connect:Disconnect()
          end
        end)

        local number = tick()

        while not enabled and tick() - number < 5 and humanoid and humanoid.Parent do
          task.wait()
        end

        if humanoid and humanoid.Parent then
          humanoid.WalkSpeed = walkSpeed
          humanoid.JumpPower = jumpPower
          humanoid.JumpHeight = jumpHeight
        end

        if humanoidRootPart and humanoidRootPart.Parent then
          humanoidRootPart.Anchored = false
        end

        if getControls then
          pcall(function() getControls:Enable() end)
        end
      end)
    end

    return
  end
end

function vdPremiumHooks.ApplyCustomSpeedKeybind(fifthValue, object, objectValue, sixthValue, callback)
  if not object then
    return
  end

  local number = tonumber(object["CustomSpeed" .. tostring(fifthValue)]) or 1

  if object.SpeedBoostEnabled and math.abs((object.SpeedBoost or 1) - number) < 0.005 then
    object.SpeedBoostEnabled = false

    if objectValue and objectValue.SpeedBoostEnabled and objectValue.SpeedBoostEnabled.setValue then
      pcall(function() objectValue.SpeedBoostEnabled.setValue(false, false) end)
    end

    if callback then
      callback("Speed Boost", "Speed Boost toggled OFF!", "warning")
    end

    return
  end

  object.SpeedBoost = number
  object.SpeedBoostEnabled = true

  if objectValue then
    if objectValue.SpeedBoost and objectValue.SpeedBoost.setValue then
      pcall(function() objectValue.SpeedBoost.setValue(number, false) end)
    end

    if objectValue.SpeedBoostEnabled and objectValue.SpeedBoostEnabled.setValue then
      pcall(function() objectValue.SpeedBoostEnabled.setValue(true, false) end)
    end
  end

  if callback then
    callback(
      "Speed Boost [Slot " .. tostring(fifthValue) .. "]",
      "Custom speed set to " .. string.format("%.2f", number) .. "x!", "success"
    )
  end
end

vdPremiumHooks.FakeLag = true
vdPremiumHooks.Desync = true
vdPremiumHooks.NoclipVaultsPallets = true
vdPremiumHooks.AlwaysFastVault = true
vdPremiumHooks.RevolverAutofarm = true
vdPremiumHooks.FrenzyParry = true
vdPremiumHooks.IgnoreAbysswalkerLunge = true
vdPremiumHooks.Stalker = true
vdPremiumHooks.SpearTrajectory = true
vdPremiumHooks.SpearAimbot = true
vdPremiumHooks.RTXGraphics = true
vdPremiumHooks.CinematicDOF = true
vdPremiumHooks.InfoBanner = true
vdPremiumHooks.BlockVaultPallets = true
vdPremiumHooks.Masked = true
vdPremiumHooks.MovementMoonwalk = true
vdPremiumHooks.CustomBackground = true
vdPremiumHooks.VisualCustomization = true
vdPremiumHooks.CustomFog = true
vdPremiumHooks.CustomLighting = true
vdPremiumHooks.CustomBloom = true
vdPremiumHooks.SunRays = true
vdPremiumHooks.KnifeSilentAim = true
vdPremiumHooks.RevolverSilentAim_Enabled = true
vdPremiumHooks.AutofarmInnocent = true
vdPremiumHooks.AutofarmSheriff = true
vdPremiumHooks.AutofarmMurderer = true
vdPremiumHooks.AutofarmAFK = true
vdPremiumHooks.UndergroundCoins = true
vdPremiumHooks.UndergroundMode = true
vdPremiumHooks.BypassToFRestrictions = true

function vdPremiumHooks.InitDBDSoundAndHud(object)
  local settings = object.Settings or _G.VD_Settings or {}
  local localPlayer = object.localPlayer or game:GetService("Players").LocalPlayer
  local isPremiumActive = object.isPremiumActive or function() return true end

  local registerConnection = object.registerConnection
    or function(fifthValue) return fifthValue end

  local showNotification = object.showNotification or function() end
  local isSpectating = object.isSpectating or function() return false end
  local getPlayerHealthPercent = object.getPlayerHealthPercent
  local readModelValue = object.readModelValue
  local activeLoop = object.activeLoop ~= nil and object.activeLoop or true
  _G.VD_DBD = {}

  local objectValue = {
    Warning = nil,
    Great = nil,
    Confirm = nil,
    HookPoint = nil,
    HookHit = nil,
    PalletDrop = nil,
    ExitReady = nil,
    GenExplode = nil,
    GateOpen = nil,
    GenDone = nil,
  }

  local enabled = false

  function _G.VD_DBD.registerListener(fifthValue)
  end

  local function getGetcustomasset()
    return getcustomasset or getsynasset
  end

  local function getBody(url)
    local requestValue = syn and syn.request or http and http.request or http_request
      or fluxus and fluxus.request or request

    local fifthValue, success, successValue

    if requestValue then
      local successResult, response = pcall(requestValue, { Url = url, Method = "GET" })

      if successResult and type(response) == "table" then
        local body = response.Body or response.body or response.response
        local statusCode = response.StatusCode or response.status_code or response.Status or 200

        if body and #body > 500 and (statusCode == 200 or statusCode == 0) then
          return body
        end
      end

      success, fifthValue = pcall(function() return game:HttpGet(url) end)

      successValue = success
      successValue = success and fifthValue and #fifthValue > 500

      if successValue then
        return fifthValue
      else
        local alternateSuccess, sixthValue = pcall(function() return game:HttpGet(url, true) end)

        if alternateSuccess and sixthValue and #sixthValue > 500 then
          return sixthValue
        end

        return nil
      end
    else
      success, fifthValue = pcall(function() return game:HttpGet(url) end)

      successValue = success
      successValue = success and fifthValue and #fifthValue > 500

      if successValue then
        return fifthValue
      else
        local successResult, sixthValue = pcall(function() return game:HttpGet(url, true) end)

        if successResult and sixthValue and #sixthValue > 500 then
          return sixthValue
        end

        return nil
      end
    end
  end

  local function callback(fifthValue)
    if not (isfile and readfile) or not isfile(fifthValue) then
      return false
    else
      local success, eighthObject = pcall(readfile, fifthValue)

      if not success or not eighthObject or #eighthObject < 5000 then
        return false
      else
        local lowercase = eighthObject:sub(1, 30):lower()

        if lowercase:find("<!doctype") or lowercase:find("<html") or lowercase:find("<head") then
          return false
        end

        return true
      end
    end
  end

  local function getMatches()
    local writefileValue = writefile
    local getcustomassetResult = getGetcustomasset()

    if not (writefileValue and readfile and isfile and getcustomassetResult) then
      return false
    else
      local count = 0

      for key, fifthValue in pairs({
        Warning = "dbd_skillcheck_sound.wav",
        Great = "dbd_skillcheck_great.ogg",
        Confirm = "dbd_skillcheck_confirm.ogg",
        HookPoint = "dbd_hook_point.ogg",
        HookHit = "dbd_hook_hit.ogg",
        PalletDrop = "dbd_pallet_drop.ogg",
        ExitReady = "dbd_exit_ready.ogg",
        GenExplode = "dbd_gen_explode.ogg",
        GateOpen = "dbd_gate_open.ogg",
        GenDone = "dbd_gen_done.ogg",
      }) do
        if callback(fifthValue) then
          local success, sixthValue = pcall(getcustomassetResult, fifthValue)

          if success and sixthValue and type(sixthValue) == "string" and #sixthValue > 0 then
            objectValue[key] = sixthValue
            count = count + 1
          end
        end
      end

      return count > 0
    end
  end

  function _G.VD_DBD.isCached()
    local matches = objectValue.Warning ~= nil
    local matchesValue = matches

    if matches then
      local matchesResult = objectValue.Great ~= nil and objectValue.Confirm ~= nil
        and objectValue.HookPoint ~= nil and objectValue.HookHit ~= nil
        and objectValue.PalletDrop ~= nil and objectValue.ExitReady ~= nil
        and objectValue.GenExplode ~= nil and objectValue.GateOpen ~= nil
        and objectValue.GenDone ~= nil

      matchesValue = matchesResult
    end

    return matchesValue
  end

  local function downloadAll(fifthValue)
    if not isPremiumActive() then
      showNotification(
        "Premium Feature +", "Unlock the Premium version to use this feature!", "warning"
      )

      return
    end

    if enabled then
      return
    end

    enabled = true

    task.spawn(function()
      local entries = {
        {
          key = "Warning",
          file = "dbd_skillcheck_sound.wav",
          url = "https://files.catbox.moe/ld6n7a.wav",
          fallbackUrl = "http://78.154.103.2:9156/sounds/dbd_warning.wav",
          name = "Warning Alert",
        },
        {
          key = "Great",
          file = "dbd_skillcheck_great.ogg",
          url = "https://files.catbox.moe/2nfj25.ogg",
          fallbackUrl = "http://78.154.103.2:9156/sounds/dbd_great.ogg",
          name = "Great Hit",
        },
        {
          key = "Confirm",
          file = "dbd_skillcheck_confirm.ogg",
          url = "https://files.catbox.moe/d726qn.ogg",
          fallbackUrl = "http://78.154.103.2:9156/sounds/dbd_confirm.ogg",
          name = "Good Hit (Confirm)",
        },
        {
          key = "HookPoint",
          file = "dbd_hook_point.ogg",
          url = "https://files.catbox.moe/bcsue6.ogg",
          fallbackUrl = "http://78.154.103.2:9156/sounds/Hooked.ogg",
          name = "Hook Point Sound",
        },
        {
          key = "HookHit",
          file = "dbd_hook_hit.ogg",
          url = "https://files.catbox.moe/bcsue6.ogg",
          fallbackUrl = "http://78.154.103.2:9156/sounds/dbd_hook.ogg",
          name = "Hook Hit Sound",
        },
        {
          key = "PalletDrop",
          file = "dbd_pallet_drop.ogg",
          url = "https://files.catbox.moe/1jx6jp.ogg",
          fallbackUrl = "https://files.catbox.moe/1jx6jp.ogg",
          name = "Pallet Drop",
        },
        {
          key = "ExitReady",
          file = "dbd_exit_ready.ogg",
          url = "https://files.catbox.moe/ubu3bg.ogg",
          fallbackUrl = "https://files.catbox.moe/ubu3bg.ogg",
          name = "Exit Ready (Endgame)",
        },
        {
          key = "GenExplode",
          file = "dbd_gen_explode.ogg",
          url = "https://files.catbox.moe/zh8nxt.ogg",
          fallbackUrl = "https://files.catbox.moe/zh8nxt.ogg",
          name = "Generator Explode",
        },
        {
          key = "GateOpen",
          file = "dbd_gate_open.ogg",
          url = "https://files.catbox.moe/8blge2.ogg",
          fallbackUrl = "https://files.catbox.moe/8blge2.ogg",
          name = "Exit Gate Opening",
        },
        {
          key = "GenDone",
          file = "dbd_gen_done.ogg",
          url = "https://files.catbox.moe/tgy10c.ogg",
          fallbackUrl = "https://files.catbox.moe/tgy10c.ogg",
          name = "Generator Completed",
        },
      }

      local getcustomassetResult = getGetcustomasset()
      local entriesValue = {}

      for index, eighthObject in ipairs(entries) do
        local bodyResult = getBody(eighthObject.url)

        if not bodyResult or #bodyResult < 500 then
          bodyResult = getBody(eighthObject.fallbackUrl)
        end

        if bodyResult and #bodyResult > 500 and writefile then
          pcall(writefile, eighthObject.file, bodyResult)
        end

        if callback(eighthObject.file) and getcustomassetResult then
          local success, soundId = pcall(getcustomassetResult, eighthObject.file)

          if success and soundId then
            objectValue[eighthObject.key] = soundId

            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Volume = 0

            table.insert(entriesValue, sound)
          end
        end

        task.wait(0.08)
      end

      if #entriesValue > 0 then
        pcall(function()
          game:GetService("ContentProvider"):PreloadAsync(entriesValue)

          for index, sixthValue in ipairs(entriesValue) do
          end
        end)
      end

      task.wait(0.1)
      enabled = false
      local matches = objectValue.Warning ~= nil
      local matchesValue = matches

      if matches then
        local matchesResult = objectValue.Great ~= nil and objectValue.Confirm ~= nil
          and objectValue.HookPoint ~= nil and objectValue.HookHit ~= nil
          and objectValue.PalletDrop ~= nil and objectValue.ExitReady ~= nil
          and objectValue.GenExplode ~= nil and objectValue.GateOpen ~= nil
          and objectValue.GenDone ~= nil

        matchesValue = matchesResult
      end

      if showNotification then
        if matchesValue then
          showNotification(
            "DBD Sounds", "All 10 DBD original audio files cached successfully!", "success"
          )
        else
          showNotification("DBD Sounds", "Sounds downloaded! Ready to use.", "info")
        end
      end
    end)
  end

  _G.VD_DBD.downloadAll = downloadAll

  local function callbackValue()
    if isSpectating and isSpectating() then
      return true
    elseif localPlayer then
      if localPlayer.Team then
        local lowercase = tostring(localPlayer.Team.Name):lower()

        if lowercase:find("spectat") or lowercase == "lobby" then
          return true
        end
      end

      if localPlayer:GetAttribute("IsSpectating") == true
        or localPlayer:GetAttribute("Spectating") == true then
        return true
      end

      return false
    else
      return false
    end
  end

  local objectResult = {}

  local function playEffect(index)
    local enabledResult = not isPremiumActive() or not settings.DBDSounds
      or not settings.DBDSounds.Enabled or callbackValue()

    local sound

    if enabledResult then
      return
    else
      local osValue = os.clock()

      if objectResult[index] and osValue - objectResult[index] < 0.08 then
        return
      else
        objectResult[index] = osValue
        local soundId = objectValue[index]

        if not soundId then
          getMatches()
          soundId = objectValue[index]
        end

        if not soundId then
          if not enabled then
            task.spawn(downloadAll)
          end

          return
        else
          local currentCamera = workspace.CurrentCamera
            or localPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("SoundService")

          sound = Instance.new("Sound")
          sound.Name = "DBD_FX_" .. index
          sound.SoundId = soundId
          sound.Volume = settings.DBDSounds and settings.DBDSounds.Volume or 1
          sound.PlayOnRemove = false
          sound.Parent = currentCamera

          pcall(function() game:GetService("SoundService"):PlayLocalSound(sound) end)
          pcall(function() sound:Play() end)

          task.delay(4, function()
            pcall(function()
              sound:Stop()
              sound:Destroy()
            end)
          end)

          return
        end
      end
    end
  end

  _G.VD_DBD.playEffect = playEffect

  local function callbackResult(eighthObject)
    local fifthValue = not eighthObject
    local matches, complete, parent

    if fifthValue or not eighthObject:IsA("Sound") then
      return nil
    else
      local lowercase = eighthObject.Name:lower()
      local lowercaseValue = tostring(eighthObject.SoundId or ""):lower()

      if lowercaseValue:find("84082802102438") then
        return "Warning"
      elseif lowercaseValue:find("87743901501619") then
        return "Great"
      elseif lowercaseValue:find("109250612395512") then
        return "Confirm"
      elseif lowercaseValue:find("108630192794160") then
        return "HookPoint"
      elseif lowercaseValue:find("78575114991208") then
        return "HookHit"
      elseif lowercaseValue:find("102000788089804") then
        return "PalletDrop"
      elseif lowercaseValue:find("90802467356489") then
        return "ExitReady"
      elseif lowercaseValue:find("97406178741226") then
        return "GenExplode"
      elseif lowercaseValue:find("123265859114838") then
        return "GateOpen"
      elseif lowercaseValue:find("124429695332529") then
        return "GenDone"
      else
        local parentValue = eighthObject.Parent
        local enabledResult = false
        local alternateEnabled = false
        local fifthEnabled = false
        local sixthEnabled = false
        local seventhEnabled = false
        local count = 0

        while true do
          count = 1 + count

          if not (count <= 6) then
            break
          end

          if not parentValue then
            break
          else
            local lowercaseResult = parentValue.Name:lower()

            if lowercaseResult:find("pallet") then
              enabledResult = true
            end

            if lowercaseResult:find("skillcheck") or lowercaseResult:find("prompt")
              or lowercaseResult:find("check") then
              alternateEnabled = true
            end

            if lowercaseResult:find("hook") then
              fifthEnabled = true
            end

            if lowercaseResult:find("generator") or lowercaseResult:find("gen") then
              sixthEnabled = true
            end

            if lowercaseResult:find("exitlever") or lowercaseResult:find("gate")
              or lowercaseResult:find("exitgate") then
              seventhEnabled = true
            end

            parentValue = parentValue.Parent
          end
        end

        if seventhEnabled then
          return "GateOpen"
        elseif enabledResult then
          return "PalletDrop"
        elseif fifthEnabled then
          if lowercase:find("hit") then
            return "HookHit"
          end

          return "HookPoint"
        else
          if sixthEnabled then
            if lowercase == "done" or lowercase:find("complete") or lowercase:find("finish")
              or lowercase:find("fixed") then
              return "GenDone"
            end

            if lowercase == "burn" or lowercase:find("explode") or lowercase:find("explosion")
              or lowercase:find("spark") or lowercase:find("boom") or lowercase:find("fail") then
              return "GenExplode"
            end
          end

          if alternateEnabled then
            if lowercase == "sound" or lowercase:find("warn") or lowercase:find("alert") then
              return "Warning"
            end

            if lowercase == "great" or lowercase:find("great") or lowercase:find("perfect") then
              return "Great"
            end

            if lowercase == "confirm" or lowercase:find("confirm") or lowercase:find("good")
              or lowercase:find("hit") or lowercase:find("success") then
              return "Confirm"
            end

            matches = lowercase == "done"

            complete = matches
            complete = matches or lowercase:find("complete")

            parent = complete

            parent = complete and eighthObject.Parent
              and eighthObject.Parent.Name:lower() == "hitbox"

            if parent then
              return "GenDone"
            end

            if lowercase == "burn" and eighthObject.Parent
              and eighthObject.Parent.Name:lower() == "hitbox" then
              return "GenExplode"
            end

            if lowercase:find("warning") or lowercase:find("alert")
              or lowercase:find("skillcheck_sound") then
              return "Warning"
            end

            if lowercase == "great" or lowercase:find("great") then
              return "Great"
            end

            if lowercase == "confirm" or lowercase:find("confirm") or lowercase:find("good") then
              return "Confirm"
            end

            return nil
          end

          matches = lowercase == "done"

          complete = matches
          complete = matches or lowercase:find("complete")

          parent = complete

          parent = complete and eighthObject.Parent
            and eighthObject.Parent.Name:lower() == "hitbox"

          if parent then
            return "GenDone"
          end

          if lowercase == "burn" and eighthObject.Parent
            and eighthObject.Parent.Name:lower() == "hitbox" then
            return "GenExplode"
          end

          if lowercase:find("warning") or lowercase:find("alert")
            or lowercase:find("skillcheck_sound") then
            return "Warning"
          end

          if lowercase == "great" or lowercase:find("great") then
            return "Great"
          end

          if lowercase == "confirm" or lowercase:find("confirm") or lowercase:find("good") then
            return "Confirm"
          end

          return nil
        end
      end
    end
  end

  local alternateObject = {}
  local fifthObject = {}

  local function hookSound(eighthObject)
    if not eighthObject or not eighthObject:IsA("Sound") or fifthObject[eighthObject] then
      return
    end

    local eighthCallback

    function eighthCallback()
      local enabledResult = callbackResult(eighthObject)

      if enabledResult then
        alternateObject[eighthObject] = enabledResult
        return enabledResult
      end

      return alternateObject[eighthObject]
    end

    local ninthCallback

    if not eighthCallback() then
      return
    else
      fifthObject[eighthObject] = eighthObject.Volume > 0 and eighthObject.Volume or 1

      if eighthObject:GetAttribute("DBD_OrigVol") == nil and eighthObject.Volume > 0 then
        eighthObject:SetAttribute("DBD_OrigVol", eighthObject.Volume)
      end

      local function setVolume()
        if settings.DBDSounds and settings.DBDSounds.Enabled and isPremiumActive()
          and not callbackValue() then
          if eighthObject.Volume > 0 then
            if eighthObject:GetAttribute("DBD_OrigVol") == nil then
              eighthObject:SetAttribute("DBD_OrigVol", eighthObject.Volume)
            end

            eighthObject.Volume = 0
          end
        else
          local dbdOrigVol = eighthObject:GetAttribute("DBD_OrigVol")
            or fifthObject[eighthObject]

          if dbdOrigVol and eighthObject.Volume == 0 then
            eighthObject.Volume = dbdOrigVol
          end
        end
      end

      setVolume()

      eighthObject:GetPropertyChangedSignal("Volume"):Connect(function()
        if settings.DBDSounds and settings.DBDSounds.Enabled and isPremiumActive()
          and not callbackValue() then
          if eighthObject.Volume > 0 then
            eighthObject.Volume = 0
          end
        end
      end)

      function ninthCallback()
        if not (settings.DBDSounds and settings.DBDSounds.Enabled and isPremiumActive())
          or callbackValue() then
          return
        else
          local fifthValue = eighthCallback()

          if not fifthValue then
            return
          end

          if eighthObject.Volume > 0 then
            eighthObject.Volume = 0
          end

          playEffect(fifthValue)
          return
        end
      end

      eighthObject.Played:Connect(ninthCallback)

      eighthObject:GetPropertyChangedSignal("Playing"):Connect(function()
        if eighthObject.Playing then
          ninthCallback()
        end
      end)

      return
    end
  end

  _G.VD_DBD.hookSound = hookSound

  function _G.VD_DBD.restoreSounds()
    for key, fifthValue in pairs(fifthObject) do
      local keyValue = key
      local sixthValue = fifthValue

      if keyValue and keyValue.Parent then
        pcall(function()
          local dbdOrigVol = keyValue:GetAttribute("DBD_OrigVol") or sixthValue

          if dbdOrigVol and dbdOrigVol > 0 then
            keyValue.Volume = dbdOrigVol
          end

          keyValue:SetAttribute("DBD_OrigVol", nil)
        end)
      end
    end
  end

  local function apply(eighthObject)
    if not eighthObject then
      return
    end

    if not (settings.DBDSounds and settings.DBDSounds.Enabled and isPremiumActive("DBDSounds")) then
      return
    else
      local fifthValue = not objectValue.Warning
      local enabledResult = fifthValue

      if not fifthValue then
        local sixthValue = not objectValue.Great or not objectValue.Confirm
          or not objectValue.HookPoint or not objectValue.HookHit or not objectValue.PalletDrop
          or not objectValue.ExitReady or not objectValue.GenExplode or not objectValue.GateOpen
          or not objectValue.GenDone

        enabledResult = sixthValue
      end

      if enabledResult then
        getMatches()
      end

      if eighthObject:IsA("Sound") then
        hookSound(eighthObject)
      else
        for index, ninthObject in ipairs(eighthObject:GetDescendants()) do
          if ninthObject:IsA("Sound") then
            hookSound(ninthObject)
          end
        end
      end

      return
    end
  end

  _G.VD_DBD.apply = apply

  function _G.VD_DBD.playPreview(index)
    local sound

    if not isPremiumActive() then
      showNotification(
        "Premium Feature +", "Unlock the Premium version to use this feature!", "warning"
      )

      return
    else
      local eighthObject = ({
        Warning = {
          file = "dbd_skillcheck_sound.wav",
          url = "https://files.catbox.moe/ld6n7a.wav",
          fallback = "http://78.154.103.2:9156/sounds/dbd_warning.wav",
        },
        Great = {
          file = "dbd_skillcheck_great.ogg",
          url = "https://files.catbox.moe/2nfj25.ogg",
          fallback = "http://78.154.103.2:9156/sounds/dbd_great.ogg",
        },
        Confirm = {
          file = "dbd_skillcheck_confirm.ogg",
          url = "https://files.catbox.moe/d726qn.ogg",
          fallback = "http://78.154.103.2:9156/sounds/dbd_confirm.ogg",
        },
        HookPoint = {
          file = "dbd_hook_point.ogg",
          url = "https://files.catbox.moe/bcsue6.ogg",
          fallback = "http://78.154.103.2:9156/sounds/Hooked.ogg",
        },
        HookHit = {
          file = "dbd_hook_hit.ogg",
          url = "https://files.catbox.moe/bcsue6.ogg",
          fallback = "http://78.154.103.2:9156/sounds/dbd_hook.ogg",
        },
        PalletDrop = {
          file = "dbd_pallet_drop.ogg",
          url = "https://files.catbox.moe/1jx6jp.ogg",
          fallback = "https://files.catbox.moe/1jx6jp.ogg",
        },
        ExitReady = {
          file = "dbd_exit_ready.ogg",
          url = "https://files.catbox.moe/ubu3bg.ogg",
          fallback = "https://files.catbox.moe/ubu3bg.ogg",
        },
        GenExplode = {
          file = "dbd_gen_explode.ogg",
          url = "https://files.catbox.moe/zh8nxt.ogg",
          fallback = "https://files.catbox.moe/zh8nxt.ogg",
        },
        GateOpen = {
          file = "dbd_gate_open.ogg",
          url = "https://files.catbox.moe/8blge2.ogg",
          fallback = "https://files.catbox.moe/8blge2.ogg",
        },
        GenDone = {
          file = "dbd_gen_done.ogg",
          url = "https://files.catbox.moe/tgy10c.ogg",
          fallback = "https://files.catbox.moe/tgy10c.ogg",
        },
      })[index]

      if not eighthObject then
        return
      else
        local getcustomassetResult = getGetcustomasset()
        local soundId = objectValue[index]

        if not soundId or not callback(eighthObject.file) then
          local bodyResult = getBody(eighthObject.url) or getBody(eighthObject.fallback)

          if bodyResult and #bodyResult > 1000 and writefile then
            pcall(writefile, eighthObject.file, bodyResult)

            if getcustomassetResult and isfile and isfile(eighthObject.file) then
              local success, fifthValue = pcall(getcustomassetResult, eighthObject.file)

              if success and fifthValue and #fifthValue > 0 then
                objectValue[index] = fifthValue
                soundId = fifthValue
              end
            end
          end
        end

        if not soundId then
          getMatches()
          soundId = objectValue[index]
        end

        if not soundId then
          showNotification(
            "DBD Sounds", "Failed to load audio. Downloading all sounds now...", "warning"
          )

          downloadAll()
          return
        else
          local currentCamera = workspace.CurrentCamera
            or localPlayer:FindFirstChildOfClass("PlayerGui") or game:GetService("SoundService")

          sound = Instance.new("Sound")
          sound.Name = "DBD_Preview_" .. index
          sound.SoundId = soundId
          sound.Volume = settings.DBDSounds and settings.DBDSounds.Volume or 1
          sound.PlayOnRemove = false
          sound.Parent = currentCamera

          pcall(function() game:GetService("SoundService"):PlayLocalSound(sound) end)
          pcall(function() sound:Play() end)

          showNotification("DBD Audio", "Playing " .. index .. " sound preview", "info")

          task.delay(4.5, function()
            pcall(function()
              sound:Stop()
              sound:Destroy()
            end)
          end)

          return
        end
      end
    end
  end

  registerConnection(workspace.DescendantAdded:Connect(function(descendant)
    if settings.DBDSounds and settings.DBDSounds.Enabled then
      if descendant:IsA("Sound") then
        pcall(hookSound, descendant)
      end
    end
  end))

  local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")

  if playerGui then
    registerConnection(playerGui.DescendantAdded:Connect(function(descendant)
      if settings.DBDSounds and settings.DBDSounds.Enabled then
        if descendant:IsA("Sound") then
          pcall(hookSound, descendant)
        end
      end
    end))
  end

  registerConnection(game:GetService("SoundService").DescendantAdded:Connect(function(descendant)
    if settings.DBDSounds and settings.DBDSounds.Enabled then
      if descendant:IsA("Sound") then
        pcall(hookSound, descendant)
      end
    end
  end))

  local function handleConnect(eighthObject)
    if not eighthObject then
      return
    end

    eighthObject.ChildAdded:Connect(function(child)
      if settings.DBDSounds and settings.DBDSounds.Enabled then
        if child.Name == "Skillcheck-gen" or child.Name:lower():find("skillcheck") then
          pcall(apply, child)
        end
      end
    end)
  end

  if localPlayer.Character then
    handleConnect(localPlayer.Character)
  end

  localPlayer.CharacterAdded:Connect(handleConnect)

  task.spawn(function()
    local enabledResult = false

    while activeLoop do
      if settings.DBDSounds and settings.DBDSounds.Enabled then
        pcall(function()
          local playerGuiValue = localPlayer:FindFirstChildOfClass("PlayerGui")
          local survivor = playerGuiValue and playerGuiValue:FindFirstChild("Survivor")
          local time = survivor and survivor:FindFirstChild("time")
          local timerLabel = time and time:FindFirstChild("TimerLabel")

          if timerLabel and timerLabel:IsA("TextLabel") then
            local substituteText = tostring(timerLabel.Text):gsub("%s+", "")

            if substituteText == "2:00" or substituteText == "02:00" then
              if not enabledResult then
                enabledResult = true
                playEffect("ExitReady")
              end
            elseif substituteText ~= "2:00" and substituteText ~= "02:00"
              and substituteText ~= "1:59" then
              enabledResult = false
            end
          end
        end)
      end

      task.wait(0.25)
    end
  end)

  task.spawn(function()
    task.wait(1)
    pcall(getMatches)

    if settings.DBDSounds and settings.DBDSounds.Enabled and not _G.VD_DBD.isCached() then
      task.spawn(downloadAll)
    end
  end)

  local sixthObject = {
    Healthy = { url = "https://files.catbox.moe/3d3yth.png", file = "dbd_hud_healthy.png" },
    Injured = { url = "https://files.catbox.moe/dj03nn.png", file = "dbd_hud_injured.png" },
    Knocked = { url = "https://files.catbox.moe/yjkbwq.png", file = "dbd_hud_knocked.png" },
    Hooked = { url = "https://files.catbox.moe/ivumkl.png", file = "dbd_hud_hooked.png" },
    Carried = { url = "https://files.catbox.moe/jgozjg.png", file = "dbd_hud_carried.png" },
    Chased = { url = "https://files.catbox.moe/him9yt.png", file = "dbd_hud_chased.png" },
    Gen = { url = "https://files.catbox.moe/731qb0.png", file = "dbd_hud_gen.png" },
  }

  local seventhObject = {}
  local enabledValue = false

  local function getGetcustomassetValue()
    return getcustomasset or getsynasset
  end

  local function getBodyValue(url)
    local requestValue = syn and syn.request or http and http.request or http_request
      or fluxus and fluxus.request or request

    local fifthValue, success, successValue

    if requestValue then
      for i = 1, 3 do
        local successResult, response = pcall(requestValue, {
          Url = url,
          Method = "GET",
          Headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
            Accept = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
          },
        })

        if successResult and type(response) == "table" then
          local body = response.Body or response.body or response.response

          local statusCode = response.StatusCode or response.status_code or response.Status
            or 200

          if body and #body > 50 and (statusCode == 200 or statusCode == 0) then
            return body
          end
        end

        task.wait(0.2)
      end

      success, fifthValue = pcall(function() return game:HttpGet(url) end)

      successValue = success
      successValue = success and fifthValue and #fifthValue > 50

      if successValue then
        return fifthValue
      else
        local successResult, sixthValue = pcall(function() return game:HttpGet(url, true) end)

        if successResult and sixthValue and #sixthValue > 50 then
          return sixthValue
        end

        return nil
      end
    else
      success, fifthValue = pcall(function() return game:HttpGet(url) end)

      successValue = success
      successValue = success and fifthValue and #fifthValue > 50

      if successValue then
        return fifthValue
      else
        local successResult, sixthValue = pcall(function() return game:HttpGet(url, true) end)

        if successResult and sixthValue and #sixthValue > 50 then
          return sixthValue
        end

        return nil
      end
    end
  end

  local function alternateCallback(fifthValue, sixthValue)
  end

  local function isCached()
    return seventhObject.Healthy ~= nil and seventhObject.Injured ~= nil
      and seventhObject.Knocked ~= nil and seventhObject.Hooked ~= nil
      and seventhObject.Carried ~= nil and seventhObject.Chased ~= nil
      and seventhObject.Gen ~= nil
  end

  local function fifthCallback()
    local getcustomassetResult = getGetcustomassetValue()

    if not (writefile and readfile and isfile and getcustomassetResult) then
      return
    end

    for key, eighthObject in pairs(sixthObject) do
      if isfile(eighthObject.file) then
        local success, fifthValue = pcall(getcustomassetResult, eighthObject.file)

        if success and fifthValue and type(fifthValue) == "string" and #fifthValue > 0 then
          seventhObject[key] = fifthValue
        end
      end
    end
  end

  local function downloadAllValue(fifthValue)
    if enabledValue then
      return
    end

    enabledValue = true

    task.spawn(function()
      local entries = {
        { key = "Healthy", item = sixthObject.Healthy },
        { key = "Injured", item = sixthObject.Injured },
        { key = "Knocked", item = sixthObject.Knocked },
        { key = "Hooked", item = sixthObject.Hooked },
        { key = "Carried", item = sixthObject.Carried },
        { key = "Chased", item = sixthObject.Chased }, { key = "Gen", item = sixthObject.Gen },
      }

      local number = #entries
      local getcustomassetResult = getGetcustomassetValue()

      for index, eighthObject in ipairs(entries) do
        local key = eighthObject.key
        local item = eighthObject.item

        if not seventhObject[key] then
          alternateCallback(
            (index - 1) / number,
            string.format("Downloading %s icon (%d/%d)...", key, index, number)
          )

          if not (isfile and isfile(item.file)) then
            local bodyResult = getBodyValue(item.url)

            if bodyResult and #bodyResult > 50 and writefile then
              pcall(writefile, item.file, bodyResult)
            end

            task.wait(0.15)
          end

          if isfile and isfile(item.file) and getcustomassetResult then
            local success, sixthValue = pcall(getcustomassetResult, item.file)

            if success and sixthValue and type(sixthValue) == "string" and #sixthValue > 0 then
              seventhObject[key] = sixthValue
            end
          end
        end

        alternateCallback(
          index / number, string.format("Cached %s icon (%d/%d)", key, index, number)
        )

        task.wait(0.05)
      end

      enabledValue = false

      if isCached() then
        if not isAutoStartup and showNotification then
          showNotification("DBD HUD", "All 7 DBD HUD icons downloaded & cached!", "success")
        end
      elseif not isAutoStartup and showNotification then
        showNotification(" DBD HUD", "Some HUD icons could not be downloaded.", "warning")
      end
    end)
  end

  _G.VD_DBD_HUD = {
    downloadAll = downloadAllValue,
    registerListener = function(fifthValue) end,
    isCached = isCached,
  }

  local function sixthCallback(index)
    if seventhObject[index] then
      return seventhObject[index]
    end

    fifthCallback()

    if seventhObject[index] then
      return seventhObject[index]
    end

    if settings.DBDHud and settings.DBDHud.Enabled and isPremiumActive() then
      downloadAllValue(nil, true)
    end

    return seventhObject[index]
  end

  task.spawn(function()
    pcall(fifthCallback)

    if settings.DBDHud and settings.DBDHud.Enabled and isPremiumActive() and not isCached() then
      downloadAllValue(nil, true)
    end
  end)

  local function seventhCallback(player)
    if not player then
      return "Healthy"
    else
      local matches = player:GetAttribute("IsCarried") == true
      local character = player.Character

      if matches or character and character:GetAttribute("IsCarried") == true
        or readModelValue and character and readModelValue(character, "IsCarried") == true then
        return "Carried"
      end

      if player:GetAttribute("IsHooked") == true
        or character and character:GetAttribute("IsHooked") == true
        or readModelValue and character and readModelValue(character, "IsHooked") == true then
        return "Hooked"
      else
        local matchesValue = player:GetAttribute("Knocked") == true
          or player:GetAttribute("IsKnocked") == true
          or character
            and (character:GetAttribute("Knocked") == true
              or character:GetAttribute("IsKnocked") == true)
          or readModelValue
            and character
            and (readModelValue(character, "Knocked") == true
              or readModelValue(character, "IsKnocked") == true)

        if character then
          local humanoid = character:FindFirstChildOfClass("Humanoid")

          if humanoid and humanoid.Health <= 0 then
            matchesValue = true
          end
        end

        if matchesValue then
          return "Knocked"
        end

        if player:GetAttribute("IsChased") == true
          or character and character:GetAttribute("IsChased") == true
          or readModelValue and character and readModelValue(character, "IsChased") == true then
          return "Chased"
        else
          local matchesResult = player:GetAttribute("Injured") == true
            or player:GetAttribute("IsInjured") == true
            or character
              and (character:GetAttribute("Injured") == true
                or character:GetAttribute("IsInjured") == true)
            or readModelValue
              and character
              and (readModelValue(character, "Injured") == true
                or readModelValue(character, "IsInjured") == true)

          if not matchesResult and character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.MaxHealth > 0 and humanoid.Health < humanoid.MaxHealth then
              matchesResult = true
            end

            if not matchesResult and getPlayerHealthPercent then
              local playerHealthPercent, fifthValue = getPlayerHealthPercent(player)

              if playerHealthPercent and fifthValue and playerHealthPercent < fifthValue then
                matchesResult = true
              end
            end
          end

          if matchesResult then
            return "Injured"
          end

          return "Healthy"
        end
      end
    end
  end

  task.spawn(function()
    while activeLoop do
      local enabledResult = settings.DBDHud and settings.DBDHud.Enabled and isPremiumActive()

      if not enabledResult then
        task.wait(0.6)
      else
        task.wait(0.15)
      end

      pcall(function()
        local playerGuiValue = localPlayer:FindFirstChildOfClass("PlayerGui")

        if not playerGuiValue then
          return
        else
          local entries = {}

          for index, fifthValue in ipairs({
            "Survivor", "Survivor-mob", "Survivor-mo", "Slasher", "Slasher-mob", "Slasher-mo",
            "Killer", "Killer-mob", "Killer-mo",
          }) do
            local findFirstChild = playerGuiValue:FindFirstChild(fifthValue)

            if findFirstChild and not table.find(entries, findFirstChild) then
              table.insert(entries, findFirstChild)
            end
          end

          for index, eighthObject in ipairs(playerGuiValue:GetChildren()) do
            if eighthObject:IsA("ScreenGui") and not table.find(entries, eighthObject) then
              local lowercase = eighthObject.Name:lower()

              if lowercase:find("survivor") or lowercase:find("slasher")
                or lowercase:find("killer") then
                table.insert(entries, eighthObject)
              end
            end
          end

          for index, eighthObject in ipairs(entries) do
            if eighthObject and eighthObject.Parent then
              local gen = eighthObject:FindFirstChild("Gen")

              local generators = gen
              generators = gen or eighthObject:FindFirstChild("Generators")

              local genholder = generators
                and (generators:FindFirstChild("genholder")
                  or generators:FindFirstChild("GenHolder")
                  or generators:FindFirstChild("Holder"))

              local imageLabel = genholder
                  and (genholder:FindFirstChild("ImageLabel")
                    or genholder:FindFirstChildWhichIsA("ImageLabel", true))
                or generators and generators:FindFirstChildWhichIsA("ImageLabel", true)

              if imageLabel then
                if enabledResult then
                  local genValue = sixthCallback("Gen")

                  if genValue and #genValue > 0 then
                    if imageLabel:GetAttribute("DBDHud_OrigImage") == nil then
                      imageLabel:SetAttribute("DBDHud_OrigImage", imageLabel.Image)
                    end

                    if imageLabel.Image ~= genValue then
                      imageLabel.Image = genValue
                    end
                  end
                else
                  local dbdHudOrigImage = imageLabel:GetAttribute("DBDHud_OrigImage")

                  if dbdHudOrigImage ~= nil then
                    imageLabel.Image = dbdHudOrigImage
                    imageLabel:SetAttribute("DBDHud_OrigImage", nil)
                  end
                end
              end

              local entriesValue = {}

              local frame = eighthObject:FindFirstChild("Frame")
                or eighthObject:FindFirstChild("Survivors")
                or eighthObject:FindFirstChild("SurvivorsFrame")

              if frame then
                for indexValue, ninthObject in ipairs(frame:GetChildren()) do
                  if ninthObject:IsA("GuiObject")
                    and (ninthObject.Name:lower():find("survivor")
                      or ninthObject:FindFirstChildWhichIsA("TextLabel", true)
                      or ninthObject:FindFirstChildWhichIsA("ImageLabel", true)) then
                    table.insert(entriesValue, ninthObject)
                  end
                end
              end

              if #entriesValue == 0 then
                for indexValue, ninthObject in ipairs(eighthObject:GetDescendants()) do
                  if ninthObject:IsA("GuiObject")
                    and (ninthObject.Name:lower():match("survivor%d+")
                      or ninthObject.Name:lower() == "survivor") then
                    table.insert(entriesValue, ninthObject)
                  end
                end
              end

              for indexValue, ninthObject in ipairs(entriesValue) do
                local textLabel = ninthObject:FindFirstChild("TextLabel")

                local findFirstChildWhichIsA = textLabel

                findFirstChildWhichIsA = textLabel
                  or ninthObject:FindFirstChildWhichIsA("TextLabel", true)

                local imageLabelValue = ninthObject:FindFirstChild("ImageLabel")

                local findFirstChildWhichIsAValue = imageLabelValue

                findFirstChildWhichIsAValue = imageLabelValue or ninthObject:FindFirstChildWhichIsA(
                  "ImageLabel", true
                )

                if findFirstChildWhichIsAValue then
                  local substituteText = findFirstChildWhichIsA and tostring(findFirstChildWhichIsA.Text):gsub("^%s+", ""):gsub(
                    "%s+$", ""
                  ) or ""

                  local player = ninthObject:GetAttribute("Player")
                    or ninthObject:GetAttribute("Username")
                    or ninthObject:GetAttribute("SurvivorName")

                  if player and type(player) == "string" and #player > 0 then
                    substituteText = player
                  end

                  local fifthValue = nil

                  if #substituteText > 0 then
                    local lowercase = substituteText:lower()

                    for indexResult, tenthObject in ipairs(Players:GetPlayers()) do
                      local lowercaseValue = tenthObject.Name:lower()
                      local lowercaseResult = tenthObject.DisplayName:lower()

                      if lowercaseValue == lowercase or lowercaseResult == lowercase
                        or lowercase:find(lowercaseValue, 1, true)
                        or lowercase:find(lowercaseResult, 1, true)
                        or lowercaseValue:find(lowercase, 1, true)
                        or lowercaseResult:find(lowercase, 1, true) then
                        fifthValue = tenthObject
                        break
                      end
                    end
                  end

                  if not fifthValue then
                    local number = tonumber(ninthObject.Name:match("%d+"))

                    if number then
                      local tenthObject = {}

                      for indexResult, eleventhObject in ipairs(Players:GetPlayers()) do
                        local team = eleventhObject.Team

                        if team
                            and (team.Name == "Survivors" or team.Name:lower():find("survivor"))
                          or eleventhObject:GetAttribute("Role") == "Survivor"
                          or eleventhObject:GetAttribute("Role") == "Survivors"
                          or team and team.Name ~= "Killer" and team.Name ~= "Spectator" then
                          table.insert(tenthObject, eleventhObject)
                        end
                      end

                      table.sort(tenthObject, function(eleventhObject, twelfthObject)
                        return eleventhObject.Name < twelfthObject.Name
                      end)

                      fifthValue = tenthObject[number]
                    end
                  end

                  if enabledResult and fifthValue then
                    local image = sixthCallback((seventhCallback(fifthValue)))

                    if image and #image > 0 then
                      if findFirstChildWhichIsAValue:GetAttribute("DBDHud_OrigImage") == nil then
                        findFirstChildWhichIsAValue:SetAttribute(
                          "DBDHud_OrigImage", findFirstChildWhichIsAValue.Image
                        )
                      end

                      if findFirstChildWhichIsAValue.Image ~= image then
                        findFirstChildWhichIsAValue.Image = image
                      end
                    end
                  else
                    local dbdHudOrigImage = findFirstChildWhichIsAValue:GetAttribute("DBDHud_OrigImage")

                    if dbdHudOrigImage ~= nil then
                      findFirstChildWhichIsAValue.Image = dbdHudOrigImage
                      findFirstChildWhichIsAValue:SetAttribute("DBDHud_OrigImage", nil)
                    end
                  end
                end
              end
            end
          end

          return
        end
      end)
    end
  end)

  local vdPremiumHooksValue = vdPremiumHooks
  vdPremiumHooksValue.ApplyDBDSounds = _G.VD_DBD and _G.VD_DBD.apply

  local vdPremiumHooksResult = vdPremiumHooks
  vdPremiumHooksResult.PlayDBDEffect = _G.VD_DBD and _G.VD_DBD.playEffect

  local alternateVdPremiumHooks = vdPremiumHooks
  alternateVdPremiumHooks.PlayDBDPreview = _G.VD_DBD and _G.VD_DBD.playPreview

  local fifthVdPremiumHooks = vdPremiumHooks
  fifthVdPremiumHooks.DownloadAllDBDSounds = _G.VD_DBD and _G.VD_DBD.downloadAll

  local sixthVdPremiumHooks = vdPremiumHooks
  sixthVdPremiumHooks.IsDBDSoundsCached = _G.VD_DBD and _G.VD_DBD.isCached

  local seventhVdPremiumHooks = vdPremiumHooks
  seventhVdPremiumHooks.RestoreDBDSounds = _G.VD_DBD and _G.VD_DBD.restoreSounds

  local eighthVdPremiumHooks = vdPremiumHooks
  eighthVdPremiumHooks.HookDBDSound = _G.VD_DBD and _G.VD_DBD.hookSound

  local ninthVdPremiumHooks = vdPremiumHooks
  ninthVdPremiumHooks.DownloadAllDBDHud = _G.VD_DBD_HUD and _G.VD_DBD_HUD.downloadAll

  local tenthVdPremiumHooks = vdPremiumHooks
  tenthVdPremiumHooks.IsDBDHudCached = _G.VD_DBD_HUD and _G.VD_DBD_HUD.isCached
end

pcall(function()
  if vdPremiumHooks.InitDBDSoundAndHud then
    local gameValue = game

    vdPremiumHooks.InitDBDSoundAndHud({
      Settings = _G.VD_Settings,
      localPlayer = gameValue:GetService("Players").LocalPlayer,
      isPremiumActive = function() return true end,
      registerConnection = function(fifthValue)
        if _G.VD_ActiveConnections then
          table.insert(_G.VD_ActiveConnections, fifthValue)
        end

        return fifthValue
      end,
      showNotification = function(fifthValue, sixthValue, seventhValue)
        if _G.VD_ShowNotification then
          _G.VD_ShowNotification(fifthValue, sixthValue, seventhValue)
        end
      end,
    })
  end
end)

vdPremiumHooks.DBDHud = true
vdPremiumHooks.DBDSounds = true
vdPremiumHooks.HideParryUI = true
vdPremiumHooks.CustomSpeedKeybinds = true
vdPremiumHooks.SimulateParryAnimation_Flag = true

