-- User CRUD HTTP server using LuaSocket and dkjson

local socket = require("socket")
local json = require("dkjson")

local USERS_FILE = "../json/users.json"
local PORT = 8080

-- Helper: Read users from JSON file
local function read_users()
    local f = io.open(USERS_FILE, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    local users, _, err = json.decode(content)
    if err then return {} end
    return users or {}
end

-- Helper: Write users to JSON file
local function write_users(users)
    local f = io.open(USERS_FILE, "w")
    if not f then return false end
    f:write(json.encode(users, { indent = true }))
    f:close()
    return true
end

-- Helper: Parse HTTP request
local function parse_request(request)
    local method, path = request:match("^(%u+) (/[%w%p]*)")
    local body = request:match("\r\n\r\n(.*)")
    return method, path, body
end

-- Helper: Send HTTP response
local function send_response(client, status, body)
    local response = "HTTP/1.1 " .. status .. "\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n\r\n" .. body
    client:send(response)
end

-- Helper: Generate unique user ID
local function gen_id()
    return tostring(math.floor(socket.gettime() * 10000))
end

-- Main server loop
local server = assert(socket.bind("*", PORT))
print("Server running on port " .. PORT)

while true do
    local client = server:accept()
    client:settimeout(2)
    -- Read request line by line until empty line (end of headers)
    local lines = {}
    while true do
        local line, err = client:receive()
        if not line or line == "" then break end
        table.insert(lines, line)
    end
    local request = table.concat(lines, "\r\n")
    -- Read body if Content-Length is present
    local headers = {}
    for _, l in ipairs(lines) do
        local k, v = l:match("^([%w-]+):%s*(.+)$")
        if k and v then headers[k:lower()] = v end
    end
    local body = ""
    if headers["content-length"] then
        local len = tonumber(headers["content-length"])
        if len and len > 0 then
            body = client:receive(len)
        end
    end
    print("[INFO] Incoming request:\n" .. request .. "\nBody:\n" .. (body or ""))
    -- Parse method and path
    local method, path = request:match("^(%u+) (/[%w%p]*)")
    local users = read_users()
    if method == "OPTIONS" then
        -- Respond to CORS preflight requests
        client:send("HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\nAccess-Control-Max-Age: 86400\r\nContent-Length: 0\r\n\r\n")
    elseif method == "GET" and path == "/favicon.ico" then
        -- Return a blank favicon
        client:send("HTTP/1.1 200 OK\r\nContent-Type: image/x-icon\r\nContent-Length: 0\r\n\r\n")
    elseif method == "GET" and path == "/users" then
        send_response(client, "200 OK", json.encode(users))
    elseif method == "POST" and path == "/users" then
        local new_user = json.decode(body)
        new_user.id = gen_id()
        table.insert(users, new_user)
        write_users(users)
        send_response(client, "201 Created", json.encode(new_user))
    elseif method == "PUT" and path:match("^/users/%w+$") then
        local id = path:match("^/users/(%w+)$")
        local update = json.decode(body)
        local found = false
        for i, user in ipairs(users) do
            if user.id == id then
                users[i] = { id = id, name = update.name, lastName = update.lastName, age = update.age, address = update.address }
                found = true
                break
            end
        end
        write_users(users)
        send_response(client, found and "200 OK" or "404 Not Found", json.encode(users))
    elseif method == "DELETE" and path:match("^/users/%w+$") then
        local id = path:match("^/users/(%w+)$")
        local idx = nil
        for i, user in ipairs(users) do
            if user.id == id then idx = i break end
        end
        if idx then
            table.remove(users, idx)
            write_users(users)
            send_response(client, "200 OK", json.encode({ success = true }))
        else
            send_response(client, "404 Not Found", json.encode({ error = "User not found" }))
        end
    else
        send_response(client, "404 Not Found", json.encode({ error = "Invalid endpoint" }))
    end
    client:close()
end