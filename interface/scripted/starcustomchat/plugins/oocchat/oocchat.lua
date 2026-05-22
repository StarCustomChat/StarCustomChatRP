require "/interface/scripted/starcustomchat/plugin.lua"

oocchat = PluginClass:new(
  { name = "oocchat" }
)

function oocchat:init(chat)
  PluginClass.init(self, chat)
end

function oocchat:formatIncomingMessage(message)
  if message.text:find("^%s*%(%(") and (message.text:find("^%s*%(%b()%)%s*$") or not message.text:find("%)%)")) then
    if message.mode == "Broadcast" or message.mode == "Local" then
      message.mode = "OOC"
    end
  end

  if message.text:find("%(%(") then
    message.text = string.gsub(message.text, "%(%(.-%)%)", "^" .. self.customChat:getColor("occtext") .. ";%1^reset;")
    message.text = string.gsub(message.text, "(.*)%(%((.-[^)][^)])$", "%1^" .. self.customChat:getColor("occtext") .. ";((%2")
  end
  return message
end

function oocchat:formatOutcomingMessage(message)
  if message.mode == "OOC" then
    message.text = string.format("((%s))", message.text)
    message.mode = self.sendingMode
  end
  return message
end