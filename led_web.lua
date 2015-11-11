-- Web temperature/humidity/blinkenlichten for what the hack
-- LED on GPIO4 (pin 2)
print("Starting AP.")

print("Configuring AP.")
cfg={}
cfg.ssid="WhatTheHack"
cfg.pwd="wth123"
wifi.ap.config(cfg)
cfg=nil

print("Configuring IP.")
cfg={}
cfg.ip="10.1.1.1"
cfg.netmask="255.255.255.0"
cfg.gateway="10.1.1.1"
wifi.ap.setip(cfg)
cfg=nil

print("AP booting now.")
wifi.setmode(wifi.SOFTAP)

print("AP started, sleeping.")
tmr.delay(1000000)

--dump ip config
ip, nm, gw=wifi.ap.getip()
print("\nIP Info:\nIP Address: "..ip.." \nNetmask: "..nm.." \nGateway Addr: "..gw.."\n")

--set led initially
function setLED()
  gpio.mode(2, gpio.OUTPUT)
  gpio.write(2, gpio.HIGH)
end

--this will toggle the LED
function toggleLED()
  ledstatus = gpio.read(2)
  if ( ledstatus == gpio.HIGH ) then
    gpio.write(2, gpio.LOW)
  else
    gpio.write(2, gpio.HIGH)
  end
end

--this will get the LED status
function getLED()
  ledread = gpio.read(2)
  if ( ledread == gpio.HIGH ) then
    return 'on'
  else 
    return 'off'
  end
end

--kick things off
print ('Doing initial LED enable')
setLED()

print ('Creating HTTP listener')

--create http server object
httpserver = net.createServer( net.TCP )

--listen for connecitons. if we get one, run the handler function below.
httpserver:listen(80, function( connection )

  connection:on( "receive", function (connection, payload )

    print( 'New connection' )
	    
    --check if the received data matches an http request for the page
    reqstr={string.find(payload,"GET / HTTP/1")}
	  if ( reqstr[1] ~= nil ) then
      --generates HTML web site
      connection:send('HTTP/1.1 200 OK\r\nConnection: close\r\nCache-Control: private, no-store\r\n\r\n\
<!DOCTYPE HTML>\
  <html><head><meta content="text/html;charset=utf-8"><title>What the Hack</title><link href="/led.css" rel="stylesheet" type="text/css"</head>\
	<body><script src="/led.js"></script><div id="header">WTH IoT Demo</div><div id="led"></div><button id="led-toggle" onClick="toggleled()">Toggle</button></body>\
</html>')

    end

    reqstr = nil

    reqstr={string.find(payload,"GET /led.js HTTP/1")}
    if ( reqstr[1] ~= nil ) then
          connection:send('HTTP/1.0 200 OK\r\nConnection: close\r\nCache-Control: private, no-store\r\nContent-Type: text/javascript\r\n\r\n\
var leddata = {};\
\
function refreshData()\
{\
    var xmlrequest = new XMLHttpRequest();\
    xmlrequest.onreadystatechange = function()\
    {\
        if (xmlrequest.readyState === XMLHttpRequest.DONE) {\
            if (xmlrequest.status === 200) {\
                leddata = JSON.parse(xmlrequest.responseText);\
                document.getElementById("led").className = leddata.status;\
            }\
        }\
    };\
    xmlrequest.open("GET", "/led.json", true);\
    xmlrequest.send();\
}\
function toggleled()\
{\
  var ledrequest = new XMLHttpRequest();\
  ledrequest.open("GET", "/toggle", true);\
  ledrequest.send();\
}\
window.setInterval(refreshData,1000);\
')
    end

    reqstr = nil

    reqstr={string.find(payload,"GET /led.css HTTP/1")}
    if ( reqstr[1] ~= nil ) then
          connection:send('HTTP/1.0 200 OK\r\nConnection: close\r\nCache-Control: private, no-store\r\nContent-Type: text/css\r\n\r\n\
body {\
    background: #edebe8;\
    color: #0F0E0F;\
    font-family: sans-serif;\
    font-size: 3em;\
}\
#led {\
  margin: 0;\
  width: 24px;\
  height: 24px;\
  border-radius: 50%;\
  box-shadow: rgba(0, 0, 0, 0.2) 0 -1px 7px 1px, inset #304701 0 -1px 9px, #89FF00 0 2px 12px;\
}\
.on {\
  background-color: #ABFF00;\
}\
')

    end

    reqstr = nil

    reqstr={string.find(payload,"GET /led.json HTTP/1")}
    if ( reqstr[1] ~= nil ) then
      ledstatus = getLED()
      connection:send('HTTP/1.0 200 OK\r\nConnection: close\r\nCache-Control: private, no-store\r\nContent-Type: application/json\r\n\r\n\
{\
  "status": "'..ledstatus..'"\
}')
    end  

    reqstr = nil

    reqstr={string.find(payload,"GET /toggle HTTP/1")}
    if ( reqstr[1] ~= nil ) then
        --toggle led
        toggleLED()
        connection:send('HTTP/1.0 200 OK\r\nConnection: close\r\nCache-Control:private, no-store\r\nContent-Type: text/plain\r\n\r\nOK')
    end

    reqstr = nil

    connection:on( "sent", function( connection ) connection:close() end )

  end )

end )

