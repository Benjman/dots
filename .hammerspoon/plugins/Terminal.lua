hs.hotkey.bind({ "cmd" }, "return", function()
	local handle =
		io.popen("source " .. os.getenv("HOME") .. "/.config/zsh/exports.zsh >/dev/null 2>&1; echo $TERMINAL")
	local command = handle:read("*l")
	handle:close()
	if command and #command > 0 then
		hs.execute("open -n -a " .. command)
	else
		print("TERMINAL variable not found")
	end
end)
