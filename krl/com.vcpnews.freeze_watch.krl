ruleset com.vcpnews.freeze_watch {
  meta {
    name "freezing_temps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares freezing_temp
  }
  global {
    event_domain = "com_vcpnews_freeze_watch"
    styles = <<
<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
</style>
>>
    freezing_temp = function(_headers){
      html:header("manage freezing_temps",styles,null,null,_headers)
      + <<
<h1>Manage freezing_temps</h1>
<table>
<tr>
<th>Name</th>
<th>Date</th>
<th>Time</th>
<th>Temp</th>
</tr>
<tr><td colspan="4">Latest</td></tr>
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
<tr><td colspan="4">Lowest</td></tr>
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
      raise com_vcpnews_freeze_watch event "freezing_temp_recorded"
        attributes event:attrs
    }
  }
  rule recordRecordTemp {
    select when com_vcpnews_freeze_watch freezing_temp_recorded
      name re#(.+)#
      temp re#([\d.]+)#
      setting(name,temp)
    pre {
      record = ent:lowest_temp{[name,"temp"]}
      lowest = record.isnull() || temp < record
    }
    if lowest.klog("lowest") then noop()
    fired {
      ent:lowest_temp{name} := event:attrs
    }
    finally {
      ent:latest_temp{name} := event:attrs
    }
  }
}
