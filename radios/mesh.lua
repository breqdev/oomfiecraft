callsign = "K9BRQ"

local modem = rednet.open("back")
local width, height = term.getSize()

local header_window = window.create(term.current(), 1, 1, width, 1)
header_window.setBackgroundColor(colors.pink)
header_window.setTextColor(colors.black)
header_window.clear()
header_window.setCursorPos(1, 1)
header_window.write("[MESH] " .. callsign)

local recv_window = window.create(term.current(), 1, 2, width, height - 2)
local send_window = window.create(term.current(), 1, height, width, 1)

local known_messages = {}

function print_message(callsigns, message)
    -- separate callsign history into first, rest
    local sender_callsign, via_callsigns = callsigns:match("^(%S+)%s?(.*)$")

    local old = term.redirect(recv_window)

    recv_window.setTextColor(colors.lightGray)
    recv_window.write("[")
    if sender_callsign == callsign then
        recv_window.setTextColor(colors.magenta)
    else
        recv_window.setTextColor(colors.orange)
    end
    recv_window.write(sender_callsign)

    if via_callsigns ~= "" then
        recv_window.setTextColor(colors.lightGray)
        recv_window.write(" via ")
        recv_window.setTextColor(colors.lightBlue)
        recv_window.write(via_callsigns)
    end

    recv_window.setTextColor(colors.lightGray)
    recv_window.write("] ")
    recv_window.setTextColor(colors.white)
    print(message)

    term.redirect(old)
end

function send_task()
    while (true) do
        send_window.clear()
        send_window.setCursorPos(1, 1)
        recv_window.setTextColor(colors.lightGray)
        send_window.write("> ")
        send_window.setTextColor(colors.white)
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
        print_message(callsign, message)
    end
end

function recv_task()
    while (true) do
        local sender, message, protocol = rednet.receive("mesh")

        local message_id, callsign_history, sender_message = message:match("%[(%x%x%x%x) (.-)%]%s(.*)")
        message_id = tonumber(message_id, 16)

        if known_messages[message_id] then
           -- nothing to do, already printed/forwarded
        else
            -- save message_id
            known_messages[message_id] = true

            -- forward message
            local output_message = string.format("[%04x %s %s] %s", message_id, callsign_history, callsign, sender_message)
            rednet.broadcast(output_message, "mesh")

            -- handle special messages
            if sender_message == "/ping" then
                local sender_callsign = callsign_history:match("(%S+)%s.*")
                local response_message = string.format("[%04x %s] Ping response to %s: Message arrived via %s", message_id, callsign, sender_callsign, callsign_history)
                rednet.send(sender, response_message, "mesh")
            end

            -- print message to terminal
            print_message(callsign_history, sender_message)
        end
    end
end

local old = term.redirect(send_window)

parallel.waitForAny(send_task, recv_task)

term.redirect(old)
