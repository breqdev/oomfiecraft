callsign = "RBMC"

rednet.open("modem_3")

while (true) do
    local sender, original_message, protocol = rednet.receive("repeater_in")

    local sender_callsign, sender_message = original_message:match("%[(.-)%]%s(.*)")
    local output_message = string.format("[%s via %s] %s", sender_callsign, callsign, sender_message)

    rednet.broadcast(output_message, "repeater_out")
end
