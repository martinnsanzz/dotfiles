--- @sync entry
-- Enter / click: folders open in place, files open in nvim straight away.
-- Inside tmux, bin/yazi-nvim swaps nvim into this pane: yazi's own way of running
-- nvim here (a blocking shell) stalls ~5s and queues every extra press.

local function is_text(mime)
	return mime:find("^text/")
		or mime:find("json")
		or mime:find("xml")
		or mime:find("javascript")
		or mime:find("empty")
end

local last_open = 0

return {
	entry = function()
		local h = cx.active.current.hovered
		if not h then
			return
		end
		if h.cha.is_dir then
			return ya.emit("enter", {})
		end

		-- If yazi already knows the file isn't text (image, pdf...), use the default opener
		local ok, mime = pcall(function() return h:mime() end)
		if ok and mime and mime ~= "" and not is_text(mime) then
			return ya.emit("open", {})
		end

		-- A double click or repeated Enter opens the file once
		local now = ya.time()
		if now - last_open < 1 then
			return
		end
		last_open = now

		local path = ya.quote(tostring(h.url))
		if os.getenv("TMUX") then
			ya.emit("shell", { "yazi-nvim " .. path, orphan = true })
		else
			ya.emit("shell", { "nvim -- " .. path, block = true })
		end
	end,
}
