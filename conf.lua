function love.conf(t)
    t.window.title = "Chuss"
    t.version = "11.4"                 -- The LÖVE version this game was made for
    t.window.width = 800              -- The window width
    t.window.height = 600             -- The window height
    t.window.resizable = false        -- Let's keep it fixed size for now
    t.window.vsync = true                -- Enable vertical sync
    t.window.minwidth = 800           -- Minimum window width
    t.window.minheight = 600          -- Minimum window height
    
    -- For debugging
    t.console = true                  -- Attach a console for debugging
end 