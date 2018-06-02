if wifi.getmode()~=wifi.NULLMODE then wifi.setmode(wifi.NULLMODE) end;
do
    local success,err=pcall(dofile,'inithw.lua');
    if not success then
        print("inithw failed: "..err);
        return
    end
end
