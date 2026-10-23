--!strict
-- Tern draws its own banners and inbox. Those never become
-- org.freedesktop.Notifications, so Quickshell never shows them.
-- Forward the same events: an agent waiting on you, an agent turn ending,
-- a long command finishing, and any other pane that raises an unseen alert.

local LONG_MS = 8000
local DEDUP_MS = 4000

local last_notify: { [number]: number } = {}
local agent_state: { [number]: string } = {}
local alerting: { [number]: boolean } = {}
local seeded = false
local tick: TimerHandle? = nil

local function clip(text: string, max: number): string
	if #text <= max then
		return text
	end
	return string.sub(text, 1, max - 3) .. "..."
end

local function pane_title(cx: WindowCx, pane: number): string
	for _, info in cx.session:panes() do
		if info.pane == pane and info.title ~= "" then
			return info.title
		end
	end
	return "Tern"
end

local function desktop(pane: number, summary: string, body: string, urgency: string)
	local now = tern.now()
	local prev = last_notify[pane]
	if prev ~= nil and now - prev < DEDUP_MS then
		return
	end
	last_notify[pane] = now
	-- No --action: that implies --wait, which holds the plugin until the
	-- toast is dismissed. Quickshell focuses Tern from the app name.
	tern.process.run({
		"notify-send",
		"--app-name=Tern",
		"--icon=so.stencil.tern",
		"--hint=string:desktop-entry:so.stencil.tern",
		"--urgency=" .. urgency,
		summary,
		body,
	}, function(_result: ProcessResult) end)
end

local function seed(cx: WindowCx)
	for _, agent in cx.agents:list() do
		agent_state[agent.pane] = agent.state
	end
	for _, info in cx.session:panes() do
		if info.alert then
			alerting[info.pane] = true
		end
	end
	seeded = true
end

local function poll(cx: WindowCx)
	if not seeded then
		seed(cx)
		return
	end

	local seen: { [number]: boolean } = {}
	for _, agent in cx.agents:list() do
		seen[agent.pane] = true
		local prev = agent_state[agent.pane]
		agent_state[agent.pane] = agent.state
		if agent.state == "waiting_input" and prev ~= "waiting_input" then
			local body = agent.last_message
			if type(body) ~= "string" or body == "" then
				body = "Waiting for you"
			end
			desktop(agent.pane, pane_title(cx, agent.pane), clip(body, 240), "critical")
		end
	end
	local gone: { number } = {}
	for pane in agent_state do
		if not seen[pane] then
			table.insert(gone, pane)
		end
	end
	for _, pane in gone do
		agent_state[pane] = nil
	end

	local still: { [number]: boolean } = {}
	for _, info in cx.session:panes() do
		if info.alert then
			still[info.pane] = true
			if not alerting[info.pane] then
				local title = if info.title ~= "" then info.title else "Tern"
				desktop(info.pane, title, "Needs attention", "normal")
			end
		end
	end
	alerting = still
end

local function schedule()
	if tick ~= nil then
		return
	end
	tick = tern.timer(2000, function(cx: WindowCx?)
		tick = nil
		if cx ~= nil then
			poll(cx)
		end
		schedule()
	end)
end

tern.on("window_start", function(cx: WindowCx)
	seed(cx)
	schedule()
end)

tern.on("command_finished", function(ev: CommandFinishedEvent, cx: WindowCx)
	if ev.took_ms < LONG_MS or ev.line == "" then
		return
	end
	local how = if ev.status == 0 then "finished" else "failed (" .. tostring(ev.status) .. ")"
	desktop(ev.pane, pane_title(cx, ev.pane), clip(ev.line, 180) .. " " .. how, "normal")
end)

tern.on("agent_finished", function(ev: AgentFinishedEvent, cx: WindowCx)
	if ev.result == "closed" then
		return
	end
	local how = if ev.result == "failed" then "failed" else "finished"
	desktop(ev.pane, pane_title(cx, ev.pane), "Agent " .. how, "normal")
end)

-- A reload does not emit window_start. Start the poll either way.
schedule()
