rex.on("terminal.bell", function(ctx)
    print("terminal.bell received in block ".. tostring(ctx.block_id))
   rex.exec {"afplay", "/System/Library/Sounds/Glass.aiff"}
end)
