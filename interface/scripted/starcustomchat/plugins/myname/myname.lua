require "/interface/scripted/starcustomchat/plugin.lua"

myname = PluginClass:new(
  { name = "myname" }
)

function myname:init(chat)
  PluginClass.init(self, chat)

  self.myNameList = player.getProperty("scc_myname_list") or jarray()
  self.coloringEnabled = root.getConfiguration("coloringscc_myname_coloring_enabled") or false
  self.pingEnabled = root.getConfiguration("scc_myname_ping_enabled") or false
  self.backgroundEnabled = root.getConfiguration("scc_myname_background_enabled") or false
  table.insert(self.myNameList, player.name())

  self:populateMessagesToHighlight()
end

function myname:populateMessagesToHighlight()
  self.highlightMessages = {}
  for _, message in ipairs(self.customChat.messages) do
    if message.myNameToHighlight then
      table.insert(self.highlightMessages, message)
    end
  end
end

function myname:onSettingsUpdate()
  self.myNameList = player.getProperty("scc_myname_list") or jarray()
  table.insert(self.myNameList, player.name())
  self.coloringEnabled = root.getConfiguration("coloringscc_myname_coloring_enabled") or false
  self.pingEnabled = root.getConfiguration("scc_myname_ping_enabled") or false
  self.backgroundEnabled = root.getConfiguration("scc_myname_background_enabled") or false
end

function myname:update(dt)
  if self.backgroundEnabled then
    for _, message in ipairs(self.highlightMessages) do
      self.customChat:highlightMessage(message, self.customChat:getColor("mynamebackground"))
    end
  end
end

function myname:formatIncomingMessage(message)
  if not message.nickname or starcustomchat.utils.clearMetatags(message.nickname) == starcustomchat.utils.clearMetatags(player.name()) or message.connection == 0 or message.mode == "CommandResult" then
    return message
  end

  if not self.coloringEnabled then
    local handled = false
    for _, name in ipairs(self.myNameList) do
      if message.text:gsub("[^%s%p]+", function(word)
        if utf8.lower(word):sub(1, #name) == utf8.lower(name) then
          if not handled then
            message.myNameToHighlight = true
            table.insert(self.highlightMessages, message)
            if self.pingEnabled and not message.edited then
              pane.playSound(self.pingSound)
              starcustomchat.utils.alert("settings.plugins.myname.name_used", message.nickname)
            end
            handled = true
          end
          return true
        end
        return false
      end) then
        return message
      end
    end
  else
    local handled = false
    message.text = message.text:gsub("[^%s%p]+", function(word)
      for _, name in ipairs(self.myNameList) do
        if utf8.lower(word):sub(1, #name) == utf8.lower(name) then
          if not handled then
            message.myNameToHighlight = true
            table.insert(self.highlightMessages, message)
            if self.pingEnabled and not message.edited then
              pane.playSound(self.pingSound)
              starcustomchat.utils.alert("settings.plugins.myname.name_used", message.nickname)
            end
            handled = true
          end
          return "^set;^" .. self.customChat:getColor("myname") .. ";" .. word .. "^reset;"
        end
      end
      return word
    end)
  end


  return message
end