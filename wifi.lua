
dofile('telnet.lua')

WIFI_NULL=0
WIFI_STAC=1
WIFI_STAF=2
WIFI_STAS=3
WIFI_AP=4
WIFI_APF=5
local wifistate=WIFI_NULL
--[[
WIFI allapotok:
 - kikapcs, sikerult is kikapcsolni (ez implicit) - led off
 - station mode, csatlakozas folyamatban - blue flash
 - station mode, hiba - red
 - station mode, siker - blue
 - wifi setup mode - yello
 - wifi setup mode, error - magenta
]]
do
    local blinker
    function setwifistate (newstate)
        wifistate=newstate
        local r,g,b=1,1,1
        if wifistate==WIFI_STAC then
            -- TODO blink led
            if blinker==nil then
                blinker=tmr.create()
                blinker:alarm(300,tmr.ALARM_AUTO,function ()
                    b=1-b
                    gpio.write(P_WIFI_B,b)
                end);
            end
        elseif wifistate==WIFI_STAF then r=0
        elseif wifistate==WIFI_STAS then b=0
        elseif wifistate==WIFI_AP then r,g=0,0
        elseif wifistate==WIFI_APF then r,b=0,0
        end
        if wifistate ~= WIFI_STAC and blinker ~= nil then
            blinker:unregister()
            blinker=nil
        end
        gpio.write(P_WIFI_R,r)
        gpio.write(P_WIFI_G,g)
        gpio.write(P_WIFI_B,b)
    end
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP,function (T)
    if wifistate==WIFI_AP or wifistate==WIFI_APF then return end
    setwifistate(WIFI_STAS)
    telnet_start()
    print("Got IP "..T.IP)
end)
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED,function (T)
    print("Connected to an AP")
end)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED,function (T)
    if wifistate==WIFI_AP or wifistate==WIFI_APF then return end
    telnet_stop()
    if wifistate==WIFI_STAC or wifistate==WIFI_STAS then
        setwifistate(WIFI_STAF)
    end
    wifi.setmode(wifi.NULLMODE,false)
    print("STA - DISCONNECTED SSID: "..T.SSID.." BSSID: "..T.BSSID.." reason: "..T.reason)
    print("wifi NULLMODE due to DISCONNECT, wifistate="..wifistate)
end)
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT,function (T)
    if wifistate==WIFI_AP or wifistate==WIFI_APF then return end
    telnet_stop()
    if wifistate==WIFI_STAC or wifistate==WIFI_STAS then
        setwifistate(WIFI_STAF)
    end
    wifi.setmode(wifi.NULLMODE,false)
    print("STA - DHCP TIMEOUT")
    print("wifi NULLMODE due to DHCP_TIMEOUT, wifistate="..wifistate)

end)
-- init.lua leaves us in NULLMODE - no need to query the status
function wifi_start() 
    if (wifistate==WIFI_AP or wifistate==WIFI_APF) then enduser_setup.stop() end
    setwifistate(WIFI_STAC)
    wifi.setmode(wifi.STATION,false)
    wifi.sta.connect()
    print("connecting to wifi")
end
function wifi_stop() 
    --wifi.sta.disconnet()
    setwifistate(WIFI_NULL)
    telnet_stop()
    wifi.setmode(wifi.NULLMODE,false)
    print("wifi NULLMODE due to button, wifistate="..wifistate)
end

function buttonsetup (pin,shortpress,longpress)
    local bt=0
    local expectdown=true
    local downtimer=tmr.create()
    downtimer:register(5000,tmr.ALARM_SEMI,function ()
        if not expectdown then
            expectdown=true
            gpio.trig(P_WIFI_BTN,"down")
            --print("expectUP timed out")
        end
    end)
    gpio.trig(pin,"down",function(l,t,c)
        if c==0 then return end
        local dt=t-bt
        if dt < 0 then dt = dt + 2147483647 end
        --if dt<0 then print("tardis in action: "..dt) end
        -- debounce: ignore event if less than 20msec passed since the previous event
        if dt<20000 then return end
        bt=t
        if expectdown then
            expectdown=false
            gpio.trig(pin,"up")
            -- we can not expect an UP event forever, impose a limit on it
            downtimer:start()
            --print("DOWN "..c)
        else
            expectdown=true
            gpio.trig(pin,"down")
            downtimer:stop()
            if dt>700000 then longpress()
            else shortpress() end
        end
    end)
end


buttonsetup(P_WIFI_BTN,
function ()
    print("WIFI butt short")
    if wifistate==WIFI_NULL or wifistate==WIFI_AP or wifistate==WIFI_APF then
        wifi_start()
        print("called wifi_start()")
    elseif wifistate==WIFI_STAC or wifistate==WIFI_STAF or wifistate==WIFI_STAS then
        wifi_stop()
    end
end,
function ()
    print("WIFI butt long")
    wifi_stop()
    enduser_setup.start(
    function()
        print("Connected to wifi as:" .. wifi.sta.getip())
        setwifistate(WIFI_STAS)
        telnet_start()
    end,
    function(err,str)
        print("enduser_setup: Err #" .. err .. ": " .. str)
        setwifistate(WIFI_APF)
    end,
    print);
    setwifistate(WIFI_AP)
end
);
