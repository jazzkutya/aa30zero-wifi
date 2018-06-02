

local defconfig={uart.getconfig(0)}
do
    local initresponse
    local initTO=tmr.create()
    initTO:alarm(300,tmr.ALARM_SINGLE,function(timer)
        uart.on("data")
        uart.alt(0)
        uart.setup(0,unpack(defconfig))
        print("AA response timeout");
        initTO=nil
    end)
    uart.alt(1)
    uart.on("data","\n",function(data)
        uart.on("data")
        uart.alt(0)
        uart.setup(0,unpack(defconfig))
        initTO:unregister()
        initTO=nil;
        print("AA response: "..data);
    end,0);
    uart.setup(0,38400,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
    uart.write(0,"off\r\n")
end

-- ATTENTION do not print anything below this line except in callbacks that do not run now

buttonsetup(P_MEAS_BTN,
function ()
    print("measurement butt short")
    --[[
    if wifistate==WIFI1_NULL or wifistate==WIFI_AP or wifistate==WIFI_APF then
        wifi_start()
        print("called wifi_start()")
    elseif wifistate==WIFI_STAC or wifistate==WIFI_STAF or wifistate==WIFI_STAS then
        wifi_stop()
    end
    ]]
end,
function ()
    print("measurement butt long")
    --[[
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
    ]]
end
);
