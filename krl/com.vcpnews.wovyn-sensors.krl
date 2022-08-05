ruleset com.vcpnews.wovyn-sensors {
  meta {
    name "wovyn_sensors"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares wovyn_sensor, history
  }
  global {
    event_domain = "com_vcpnews_wovyn_sensors"
    mapping = {
      "Wovyn_2BD707": "Attic East",
      "Wovyn_162EB3": "Attic West",
      "Wovyn_163ECD": "Kitchen",
      "Wovyn_746ABF": "Patio",
    }
    makeMT = function(ts){
      MST = time:add(ts,{"hours": -7});
      MDT = time:add(ts,{"hours": -6});
      MDT > "2022-11-06T02" => MST |
      MST > "2022-03-13T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
    temps = function(a,tt,i){
      a+(i%2==0 => <<<tr>
<td title="#{tt}">#{tt.makeMT().ts_format()}</td>
>> | <<
<td>#{tt}°F</td>
</tr>
>>)
    }
    wovyn_sensor = function(_headers){
      one_sensor = function(v,k){
        <<<h2 title="#{k}">#{mapping{k}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{v.slice(v.length()-2,2).reduce(temps,"").join("")}
</table>
<a href="history.html?name=#{k}">history</a>
>>
      }
      html:header("manage wovyn_sensors","",null,null,_headers)
      + <<
<h1>Manage wovyn_sensors</h1>
#{ent:record.map(one_sensor).values().join("")}
>>
      + html:footer()
    }
    history = function(name,_headers){
      html:header("sensor "+name,"",null,null,_headers)
      + <<
<h1>sensor #{name}</h1>
<h2>#{mapping{name}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{ent:record{name}.reduce(temps,"").join("")}
</table>
>>
      + html:footer()
    
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["wovyn_sensors"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise com_vcpnews_wovyn_sensors event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when com_vcpnews_wovyn_sensors factory_reset
    foreach wrangler:channels(["wovyn_sensors"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule prepare {
    select when com_vcpnews_wovyn_sensors heartbeat
      where ent:record.isnull()
    fired {
      ent:record := {}
    }
  }
  rule acceptHeartbeat {
    select when com_vcpnews_wovyn_sensors heartbeat
      eventDomain re#^wovyn.emitter$#
    pre {
      device = event:attrs{["property","name"]}
      temps = event:attrs{["genericThing","data","temperature"]}
      tempF = temps.head(){"temperatureF"}
      record = ent:record{device}.defaultsTo([]).append([time:now(),tempF])
    }
    fired {
      ent:record{device} := record
    }
  }
}
