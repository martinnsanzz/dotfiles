-- Clicking a file opens it in vim; clicking a folder still just moves to it
function Entity:click(event, up)
	if up or event.is_middle then
		return
	end
	ya.emit("reveal", { self._file.url })
	if not self._file.cha.is_dir then
		ya.emit("plugin", { "open-vim" })
	end
end
