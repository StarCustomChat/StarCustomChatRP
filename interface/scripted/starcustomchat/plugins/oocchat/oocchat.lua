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
    local oocStyle = "^" .. self.customChat:getColor("occtext") .. ";^font=" .. self.customChat:getFont("occtext") .. ";"

    message.text = string.gsub(message.text, "%(%(.-%)%)", function(text)
      return starcustomchat.utils.styleText(message, oocStyle, text)
    end)
    message.text = string.gsub(message.text, "(.*)%(%((.-[^)][^)])$", function(prefix, text)
      if text:find("%)%)") then
        return prefix .. "((" .. text
      end
      return prefix .. starcustomchat.utils.styleStart(message, oocStyle) .. "((" .. text
    end)
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
