if wifi.getmode()~=wifi.NULLMODE then wifi.setmode(wifi.NULLMODE) end;
do
    local success,err=pcall(dofile,'inithw.lua');
    if not success then
        print("inithw failed: "..err);
        return
    end
end

if gpio.read(P_MEAS_BTN)==0 then
    -- measurement button is held during boot - abort startup
    print("Entering service mode");
    return
end

-- TODO start our stuff after a delay
print("Starting up soon...")
tmr.create():alarm(4000, tmr.ALARM_SINGLE, function ()
    if gpio.read(P_MEAS_BTN)==0 then
        print("Entering service mode");
        return
    end
    if file.open("service.mod") == nil then
        print("NOW")
        local success,err=pcall(dofile,"application.lua");
        if not success then
            print("application.lua failed: "..err);
            return
        end
    else
        print("Entering service mode");
        file.close("service.mod");
    end
end)
