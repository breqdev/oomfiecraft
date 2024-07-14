callsign = "K9BRQ"

local width, height = term.getSize()

local send_window = window.create(term.current(), 1, 1, width, 9)
local recv_window = window.create(term.current(), 1, 11, width, height - 11)


local modem = rednet.open("back")

function send_task()
    while (true) do
        local message = io.read()

        if message == "exit" then
            return
        end

        rednet.broadcast("[" .. callsign .. "] " .. message, "repeater_in")
    end
end

function recv_task()
    while (true) do
        local sender, message, protocol = rednet.receive("repeater_out")

        local old = term.redirect(recv_window)
        print(message)
        term.redirect(old)
        if old.restoreCursor then
            old.restoreCursor()
        end
    end
end

local old = term.redirect(send_window)

parallel.waitForAny(send_task, recv_task)

term.redirect(old)
