hs.hotkey.bind({ "cmd" }, "B", function()
	local handle = io.popen("source " .. os.getenv("HOME") .. "/.config/zsh/exports.zsh >/dev/null 2>&1; echo $BROWSER")
	local command = handle:read("*l")
	handle:close()
	if command and #command > 0 then
		hs.execute("open -n -a " .. command)
	else
		print("BROWSER variable not found")
	end
end)
