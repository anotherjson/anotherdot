hl.window_rule({
  name = "firefox-translucent",
  match = { class = "firefox" },
  opacity = "0.9 0.85",
})

-- Ignore maximize requests from every app.
hl.window_rule({
  name = "suppress-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland.
hl.window_rule({
  name = "fix-xwayland-drags",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})
