require "/interface/scripted/starcustomchat/plugin.lua"

rpchat = PluginClass:new(
  { name = "rpchat" }
)

function rpchat:onSendMessage(message)
  if message.mode == "Announcement" then
    local originalText = message.text
    message.text = self.announcementPrefix .. originalText
    chat.send(message.text, "Broadcast", true, message.data)
    player.say(originalText)
  end
end

function rpchat:formatIncomingMessage(message)

  if string.find(message.text, self.announcementPrefix, 1, true) then
    message.mode = "Announcement"
    message.text = string.sub(message.text, string.len(self.announcementPrefix) + 1)
    message.portrait = message.portrait and message.portrait ~= '' and message.portrait or self.modeIcons.server
  end

  local actionStyle = "^" .. self.customChat:getColor("actionstext") .. ";^font=" .. self.customChat:getFont("actionstext") .. ";"
  local thoughtsStyle = "^" .. self.customChat:getColor("thoughtstext") .. ";^font=" .. self.customChat:getFont("thoughtstext") .. ";"

  message.text = string.gsub(message.text, "%b**", function(text)
    return starcustomchat.utils.styleText(message, actionStyle, text)
  end)
  message.text = string.gsub(message.text, "%b%%", function(text)
    return starcustomchat.utils.styleText(message, thoughtsStyle, text)
  end)
  
  return message
end
