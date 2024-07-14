callsign = "K9BRQ"

w, h = term.getSize()

s_win = window.create(term.current(), 1, 1, w, 9)
r_win = window.create(term.current(), 1, 11, w, h-11)


m = rednet.open("back")

function send()
    while (true) do
        msg = io.read()

        if msg == "exit" then
            return
        end

        rednet.broadcast("[" .. callsign .. "] " .. msg, "repeater_in")
    end
end

function recv()
    while (true) do
        s, m, p = rednet.receive("repeater_out")
    
        local old = term.redirect(r_win)
        print(m)
        term.redirect(old)
        if old.restoreCursor then
            old.restoreCursor()
        end
    end
end

local old = term.redirect(s_win)

parallel.waitForAny(send, recv)

term.redirect(old)