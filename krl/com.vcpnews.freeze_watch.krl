ruleset com.vcpnews.freeze_watch {
  meta {
    name "freezing_temps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares freezing_temp
  }
  global {
    event_domain = "com_vcpnews_freeze_watch"
    freezing_temp = function(_headers){
      html:header("manage freezing_temps","",null,null,_headers)
      + <<
<h1>Manage freezing_temps</h1>
<table>
<tr>
<th>Name</th>
<th>Date</th>
<th>Temp</th>
</tr>
#{
ent:freezing_temps.defaultsTo([])
                  .reverse()
                  .map(function(v){
<<<tr>
<td>#{v{"name"}}</td>
<td>#{v{"time"}}</td>
<td>#{v{"temp"}}</td>
</tr>
>>}).join("")
}
</table>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["freezing_temps"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise com_vcpnews_freeze_watch event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when com_vcpnews_freeze_watch factory_reset
    foreach wrangler:channels(["freezing_temps"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule recordFreezingTemps {
    select when com_vcpnews_wovyn_sensors temp_recorded
      where event:attr("temp") <= 32
    fired {
      ent:freezing_temps := ent:freezing_temps.defaultsTo([]).append(event:attrs)
      raise com_vcpnews_freeze_watch event "freezing_temp_recorded"
        attributes event:attrs
    }
  }
}
