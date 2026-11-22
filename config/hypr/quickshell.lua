hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell -n")
end)

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("quickshell ipc call applauncher toggle"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("quickshell ipc call clipboard toggle"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("quickshell ipc call wallpaper toggle"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("quickshell ipc call focus toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("quickshell ipc call lockscreen lock"))
