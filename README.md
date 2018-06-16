# aa30zero-wifi
HF antenna analyzer using Rigexpert AA-30.ZERO and esp8266 nodemcu

**WORK IN PROGRESS**

## Goal

Create a battery powered portable device with which you can make measurements. Measurements can be downloaded via WIFI and replayed to Antscope or converted to csv.

## user interface

2 RGB leds and 2 buttons:
* WIFI button, WIFI LED
* Measuement button, Measurement LED

### WIFI

Short press the WIFI button to connect or disconnect from WIFI.
Long press the WIFI button to enter WIFI end-user-setup.

WIFI LED indicates status:
* blinking blue: connecting to an AP (a wifi network)
* blue: connected to an AP
* red: failed to connect to an AP
* yellow: in end user setup (see https://nodemcu.readthedocs.io/en/latest/en/modules/enduser-setup/ )
* magenta: error in end user setup


### measurement

Short press the Measurement button to start a measurement. Measurements are saved on the NodeMCU flash (spiffs).

Measurement LED indicates status:
* flashing between off/blue/green/cyan - measurement in progress. Blue is blinking, green is toggling each time a line is received from AA-30.Zero
* red: error happened
* green: a measurement finished successfully

Measurements are saved as m/aa-0.txt
The number is inceremented for each new mesurement (actually it finds the first non-existent filename)

## Current state

working:
* button handling :) deoupling, long/short detection
* wifi end user setup
* connecting to wifi
* there is a "telnet server" to access the Lua interpreter, but stderr can not be redirected with current nodemcu-firmware so this is mosly useless
* prefedined measurement: center frequency 15Mhz, range 30Mhz, 1001 points
* LEDs for all of the above
* AA-30.Zero communication timeout

## TODO

* file I/O error handling
* telnet-AA30 uart proxy
* webserver
  * list of measurement
  * download a measurement
  * delete a measurement
  * dleete all measurements
  * measurement config
* replay measurement with socat to Antscope running with wine
* script to convert measurement to csv
* schematic
* notes about schematic, pin usage, warning about SD_D2
* clarify end user setup in README
* battery power
* box
* use sntp and use datetime for naming measurement files if available at time of measurement start
* reset button? AA-30.ZERO has to be powered down then up on a reset. Or just flick the power switch.
* ignore wifi button while measurement is in progress.
* disconnect from wifi before measurement?





