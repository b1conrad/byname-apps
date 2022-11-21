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
<th>Time</th>
<th>Temp</th>
</tr>
#{
ent:latest_temp.map(function(v){
                 parts = v{"time"}.split(re#[T.]#)
                 date = parts.head()
                 time = parts[1]
<<<tr>
<td>#{v{"name"}}</td>
<td>#{date}</td>
<td>#{time}</td>
<td>#{v{"temp"}}</td>
</tr>
>>}).values().join("")
}
#{
ent:lowest_temp.map(function(v){
                 parts = v{"time"}.split(re#[T.]#)
                 date = parts.head()
                 time = parts[1]
<<<tr>
<td>#{v{"name"}}</td>
<td>#{date}</td>
<td>#{time}</td>
<td>#{v{"temp"}}</td>
</tr>
>>}).values().join("")
}
</table>
>>
      + html:footer()
    }
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    by_num = function(key){
      function(a,b){a{key} <=> b{key}}
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
  rule convertState {
    select when com_vcpnews_freeze_watch factory_reset
    pre {
      lowestShed = ent:freezing_temps.filter(function(v){v{"name"}=="Shed"})
                                    .sort(by_num("temp"))
                                    .head()
      lowestPorch = ent:freezing_temps.filter(function(v){v{"name"}=="Porch"})
                                     .sort(by_num("temp"))
                                     .head()
      latestShed = ent:freezing_temps.filter(function(v){v{"name"}=="Shed"})
                                    .sort(by("time"))
                                    .reverse()
                                    .head()
      latestPorch = ent:freezing_temps.filter(function(v){v{"name"}=="Porch"})
                                     .sort(by("time"))
                                     .reverse()
                                     .head()
    }
    fired {
      ent:lowest_temp := {}
      ent:lowest_temp{"Shed"} := lowestShed
      ent:latest_temp{"Shed"} := latestShed
      ent:latest_temp := {}
      ent:lowest_temp{"Porch"} := lowestPorch
      ent:latest_temp{"Porch"} := latestPorch
    }
  }
  rule recordFreezingTemps {
    select when com_vcpnews_wovyn_sensors temp_recorded
      where event:attr("temp") <= 32
    fired {
      raise com_vcpnews_freeze_watch event "freezing_temp_recorded"
        attributes event:attrs
    }
  }
  rule recordRecordTemp {
    select when com_vcpnews_wovyn_sensors freezing_temp_recorded
      name re#(.+)#
      temp re#([.\d]+)#
      setting(name,temp)
    pre {
      record = ent:lowest_temp{[name,"temp"]}
      lowest = record.isnull() || temp < record
    }
    if lowest then noop()
    fired {
      ent:lowest_temp{name} := event:attrs
    }
    finally {
      ent:latest_temp{name} := event:attrs
    }
  }
}
