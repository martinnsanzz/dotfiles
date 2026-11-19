--- @sync entry
-- q: in the Option+e popup (bin/tree-popup), close the popup through tmux
-- right away; yazi 26 takes ~5s to give the terminal back when it quits.

return {
	entry = function()
		if os.getenv("YAZI_POPUP") and os.getenv("TMUX") then
			ya.emit("shell", { "tmux display-popup -C", orphan = true })
		else
			ya.emit("quit", {})
		end
	end,
}
