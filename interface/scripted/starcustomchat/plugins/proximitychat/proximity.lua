require "/interface/scripted/starcustomchat/plugin.lua"

proximitychat = PluginClass:new(
  { name = "proximitychat" }
)

function proximitychat:init(chat)
  PluginClass.init(self, chat)
  
  self.proximityRadius = root.getConfiguration("scc_proximity_radius") or self.proximityRadius
  self.receivingRestricted = root.getConfiguration("scc_proximity_restricted") or false
  widget.setText("lytProxChangeRadius.lblProxRadiusValue", self.proximityRadius)
  widget.setSliderRange("lytProxChangeRadius.sldProxRadius", 0, self.proximityMax - self.proximityMin, 1)
  widget.setSliderValue("lytProxChangeRadius.sldProxRadius", self.proximityRadius - self.proximityMin)

  -- Auto-hide timer: onCursorOverride will reset this when the cursor is over the chat.
  self._proxShowTimeout = 0.15
  self._proxShowTimer = 0

  self.stagehandEnabled = false
end

function proximitychat:registerStagehandHandlers(handlers)
  self.stagehandEnabled = handlers and handlers["sendProxyMessage"]
end

function proximitychat:onSendMessage(message)
  if message.mode == "Proximity" then
    message.proximityRadius = self.proximityRadius
    
    if self.stagehandEnabled and self.uniqueStagehandType and self.uniqueStagehandType ~= "" then
      starcustomchat.utils.sendMessageToUniqueStagehand(self.uniqueStagehandType, "icc_sendMessage", message)
    elseif self.stagehandEnabled and self.stagehandType and self.stagehandType ~= "" then
      starcustomchat.utils.createStagehandWithData(self.stagehandType, {message = "sendProxyMessage", data = message})
    else
      
      local function sendMessageToPlayers()
        local position = player.id() and world.entityPosition(player.id())
        if position then
          local players = world.playerQuery(position, message.proximityRadius)
          for _, pl in ipairs(players) do 
            world.sendEntityMessage(pl, "scc_add_message", message)
          end
          return true
        end
      end

      local sendMessagePromise = {
        finished = sendMessageToPlayers,
        succeeded = function() return true end
      }

      promises:add(sendMessagePromise)
    end

    if not message.silent then
      player.say(message.text)
    end
  end
end

function proximitychat:formatIncomingMessage(message)
  if message.mode == "Proximity" then
    if self.receivingRestricted and message.connection then
      local authorEntityId = starcustomchat.utils.connectionToEntityId(message.connection)
      if world.entityExists(authorEntityId) then
        if world.magnitude(world.entityPosition(player.id()), world.entityPosition(authorEntityId)) > self.proximityRadius then
          message.text = ""
        end
      end
    end
    message.portrait = message.portrait and message.portrait ~= "" and message.portrait or message.connection
  end
  return message
end

function proximitychat:onSettingsUpdate(data)
  if data then
    if data.newProximityRadius then
      self.proximityRadius = data.newProximityRadius
      widget.setText("lytProxChangeRadius.lblProxRadiusValue", self.proximityRadius)
      widget.setSliderValue("lytProxChangeRadius.sldProxRadius", self.proximityRadius - self.proximityMin)
      root.setConfiguration("scc_proximity_radius", self.proximityRadius)
    elseif data.newProximityRestriction ~= nil then
      self.receivingRestricted = data.newProximityRestriction or false
      root.setConfiguration("scc_proximity_restricted", self.receivingRestricted)
    end
  end
end

function proximitychat:onCursorOverride(screenPosition)
  local id = findButtonByMode("Proximity")

  if player.id() and world.entityPosition(player.id()) then
    if widget.inMember("rgChatMode." .. id, screenPosition) then
      starcustomchat.utils.drawCircle(world.entityPosition(player.id()), self.proximityRadius, "green")
    end

    if widget.getSelectedData("rgChatMode").mode == "Proximity" and (
    widget.inMember("rgChatMode." .. id, screenPosition) or widget.inMember("lytProxChangeRadius", screenPosition)) then
      widget.setVisible("lytProxChangeRadius", true)
      self._proxShowTimer = self._proxShowTimeout

      if widget.inMember("lytProxChangeRadius.sldProxRadius", screenPosition) then
        starcustomchat.utils.drawCircle(world.entityPosition(player.id()), self.proximityRadius, "green")
      elseif string.find(widget.getChildAt(screenPosition), "btnTreshold%d") then
        local treshold = widget.getData(widget.getChildAt(screenPosition):sub(2)).treshold
        starcustomchat.utils.drawCircle(world.entityPosition(player.id()), self.proximityRadius, "green")
        starcustomchat.utils.drawCircle(world.entityPosition(player.id()), math.floor(treshold * (self.proximityMax - self.proximityMin) + self.proximityMin), "yellow")
      end
    else
      widget.setVisible("lytProxChangeRadius", false)
      self._proxShowTimer = 0
    end
  end
end

function proximitychat:update(dt)
  if self._proxShowTimer and self._proxShowTimer > 0 then
    self._proxShowTimer = math.max(self._proxShowTimer - dt, 0)
    if self._proxShowTimer == 0 then
      widget.setVisible("lytProxChangeRadius", false)
    end
  end
end

function proximitychat:onLocaleChange()
  widget.setText("lytProxChangeRadius.lblRadius", starcustomchat.utils.getTranslation("settings.proximity.radius"))
end


function proximitychat:onCustomButtonClick(widgetName)
  if widgetName == "sldProxRadius" then
    self:onSettingsUpdate({
      newProximityRadius = widget.getSliderValue("lytProxChangeRadius.sldProxRadius") + self.proximityMin
    })
  elseif string.find(widgetName, "btnTreshold%d") then
    local treshold = widget.getData("lytProxChangeRadius." .. widgetName).treshold
    self.proximityRadius = math.floor(treshold * (self.proximityMax - self.proximityMin) + self.proximityMin)
    widget.setSliderValue("lytProxChangeRadius.sldProxRadius", self.proximityRadius - self.proximityMin)
    self:onSettingsUpdate({ newProximityRadius = self.proximityRadius })
  end
end