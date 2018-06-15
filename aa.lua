

local defconfig={uart.getconfig(0)}
do
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

M_RUN=1
M_ERROR=2
M_SUCCESS=3
do
    local blinker
    function setmled (newstate)
        --wifistate=newstate
        local r,g,b=1,1,1
        if newstate==M_RUN then
            -- blink blue led
            if blinker==nil then
                blinker=tmr.create()
                blinker:alarm(300,tmr.ALARM_AUTO,function ()
                    b=1-b
                    gpio.write(P_MEAS_B,b)
                end);
            end
        elseif newstate==M_ERROR then r=0
        elseif newstate==M_SUCCESS then g=0
        end
        if newstate ~= M_RUN and blinker ~= nil then
            blinker:unregister()
            blinker=nil
        end
        gpio.write(P_MEAS_R,r)
        gpio.write(P_MEAS_G,g)
        gpio.write(P_MEAS_B,b)
    end
end
do
    local cnt=-1
    local fn
    local comTO
    local greens={gpio.HIGH,gpio.LOW}
    local inputcnt=0
    function new_mfile()
        local file_exists=file.exists
        repeat cnt=cnt+1; fn="m/aa-"..cnt..".txt"
        until not file_exists(fn)
        return file.open(fn,"w")
    end
    local cmdi;
    function m_start()
        if cmdi then return end-- measurement already in progress
        local uart_on,uart_alt,uart_setup,uart_write = uart.on,uart.alt,uart.setup,uart.write
        local string_byte,string_sub = string.byte,string.sub

        local f
        local cmds={"VER\r\n","fq15000000\r\n","sw30000000\r\n","frx1000\r\n"}
        cmdi=1
        uart_alt(1)
        inputcnt=0
        uart_on("data","\n",function(data)
            if not cmdi then return end -- no measurement in progress. probably aborted by a timeout
            -- reset the comTO timer
            comTO:stop()
            comTO:start()
            -- invert the green led
            inputcnt=inputcnt+1
            gpio.write(P_MEAS_G,greens[1+bit.band(inputcnt,1)])
            f:write("<"..data)
            if string_byte(data)==13 then data=string_sub(data,2) end
            if string_byte(data,-2)==13 then data=string_sub(data,1,-3)
            else data=string_sub(data,1,-2) end
            -- end of respone if:
            -- command is VER
            -- or data=="OK"
            if (cmds[cmdi]=="VER\r\n" or data=="OK") then
                cmdi=cmdi+1
                if cmdi > #cmds then
                    -- we executed all commands
                    uart_on("data")
                    uart_alt(0)
                    uart_setup(0,unpack(defconfig))
                    comTO:unregister()
                    comTO=nil;
                    cmdi=nil
                    f:close()
                    f=nil
                    -- set led
                    setmled(M_SUCCESS)
                    print("AA measurement finished. file: "..fn);
                    return
                end
                f:write(">"..cmds[cmdi])
                uart_write(0,cmds[cmdi])
            end
        end,0)
        f=new_mfile()
        f:write(">"..cmds[cmdi])
        f:flush()
        -- start blinking blue
        setmled(M_RUN)
        comTO=tmr.create()
        comTO:alarm(500,tmr.ALARM_SINGLE,function(timer)
            cmdi=nil
            uart.on("data")
            uart.alt(0)
            uart.setup(0,unpack(defconfig))
            f:close()
            f=nil
            print("AA response timeout during measurement");
            comTO=nil
            -- set led
            setmled(M_ERROR)
            gpio.write(P_WIFI_B,0)
            gpio.write(P_WIFI_G,1)
            gpio.write(P_WIFI_B,1)
        end)
        uart_setup(0,38400,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
        uart_write(0,cmds[cmdi])
    end
end

-- ATTENTION do not print anything below this line except in callbacks that do not run now

buttonsetup(P_MEAS_BTN,
function ()
    print("measurement butt short")
    m_start()
end
);
