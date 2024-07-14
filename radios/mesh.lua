callsign = "K9BRQ"

local modem = rednet.open("back")
local width, height = term.getSize()

local send_window = window.create(term.current(), 1, 1, width, 9)
local recv_window = window.create(term.current(), 1, 11, width, height - 11)

local known_messages = {}

function send_task()
    while (true) do
        local message = io.read()

        if message == "exit" then
            return
        end

        local message_id = math.random(1, 0xFFFF)
        known_messages[message_id] = true

        -- message format: [XXXX callsign] message
        -- where XXXX is the message id, 4 hex digits
        -- and callsign is a list of callsigns separated by spaces by which the message has been relayed
        local output_message = string.format("[%04x %s] %s", message_id, callsign, message)
        rednet.broadcast(output_message, "mesh")

        -- manually print this message ourselves
        local old = term.redirect(recv_window)
        print(message)
        term.redirect(old)
        if old.restoreCursor then
            old.restoreCursor()
        end
    end
end

function recv_task()
    while (true) do
        local sender, message, protocol = rednet.receive("mesh")

        local message_id, callsign_history, sender_message = original_message:match("%[(%x%x%x%x) (.-)%]%s(.*)")

        if known_messages[message_id] then
           -- nothing to do, already printed/forwarded
        else
            -- save message_id
            known_messages[message_id] = true

            -- forward message
            local output_message = string.format("[%04x %s %s] %s", message_id, callsign_history, callsign, sender_message)
            rednet.broadcast(output_message, "mesh")

            -- print message to terminal
            local old = term.redirect(recv_window)
            print(message)
            term.redirect(old)
            if old.restoreCursor then
                old.restoreCursor()
            end
        end
    end
end

local old = term.redirect(send_window)

parallel.waitForAny(send_task, recv_task)

term.redirect(old)
