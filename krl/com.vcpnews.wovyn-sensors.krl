ruleset com.vcpnews.wovyn-sensors {
  meta {
    name "wovyn_sensors"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares wovyn_sensor
  }
  global {
    event_domain = "com_vcpnews_wovyn_sensors"
    wovyn_sensor = function(_headers){
      temps = function(a,tt,i){
        a+(i%2 => <<<tr>
<td>tt</td>
>> | <<
<td>tt</td>
</tr>
>>)
      }
      one_sensor = function(v,k){
        <<<h2>k</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{v.reduce(temps,"").join("")}
</table>
>>
      }
      html:header("manage wovyn_sensors","",null,null,_headers)
      + <<
<h1>Manage wovyn_sensors</h1>
#{ent:record.map(one_sensor).values().join("")}
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
