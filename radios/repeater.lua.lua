callsign = "RBMC"

rednet.open("modem_3")

while (true) do
    local s, m, p = rednet.receive("repeater_in")
    
    local c, mm = m:match("%[(.-)%]%s(.*)")
    local mmm = string.format("[%s via %s] %s", c, callsign, mm)
    
    rednet.broadcast(mmm, "repeater_out")
end