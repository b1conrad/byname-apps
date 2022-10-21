ruleset com.vcpnews.wovyn-sensors {
  meta {
    name "wovyn_sensors"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares wovyn_sensor, history, export_tsv
,rawData
  }
  global {
rawData = function(){
  ent:record
}
    event_domain = "com_vcpnews_wovyn_sensors"
    mapping = {
      "Wovyn_2BD707": "Shed",
      "Wovyn_162EB3": "Attic West",
      "Wovyn_163ECD": "Kitchen",
      "Wovyn_746ABF": "Porch",
    }
    daysInRecord = function(){ // finds all dates in the data
      firstHour = function(v,i){
        i%2==0
        &&
        v.encode().decode().match(re#T06#) // assuming MDT
      }
      flatten = function(a,v){a.append(v)}
      justDate = function(t){t.split("T").head()}
      asSet = function(a,t){a.union(t)}
      ent:record
        .values()
        .map(function(list){list.filter(firstHour)})
        .reduce(flatten,[])
        .map(justDate)
        .reduce(asSet,[])
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
        vlen = v.length()
        <<<h2 title="#{k}">#{mapping{k}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{v.slice(vlen-2,vlen-1).reduce(temps,"").join("")}
</table>
<a href="history.html?name=#{k}">history</a>
(#{vlen/2-1} more)
>>
      }
      html:header("manage wovyn_sensors","",null,null,_headers)
      + <<
<h1>Manage wovyn_sensors</h1>
#{ent:record.map(one_sensor).values().join("")}
<h2>Operations</h2>
<h3>Export records</h3>
<a href="export_tsv.txt" target="_blank">export</a> (in new tab)
<h3>Prune older data</h3>
<form action="#{meta:host}/sky/event/#{meta:eci}/prune/#{event_domain}/prune_all_needed">
<label for="cutoff">Data older than:</label>
<select name="cutoff" id="cutoff" required>
  <option value="">Choose date</option>
#{
daysInRecord()
  .map(function(d){ // assuming MDT
    <<  <option value="#{d}T06">#{d}</option>
>>})
  .join("")
}</select>
<button type="submit">Prune</button>
</form>
>>
      + html:footer()
    }
    cutoff_index = function(list,cutoff_date){
      find_index = function(answer,v,i){
        answer >= 0      => answer | // already found cutoff
        i%2              => answer | // temp value
        v < cutoff_date  => answer | // date before cutoff
                            i        // cutoff index
      }
      list.reduce(find_index,-1)
    }
    pruned_list = function(list,cutoff_date){
      index = cutoff_date => list.cutoff_index(cutoff_date) | 0
      sanity = (index%2==0).klog("index even?")
      sanity => list.slice(index,list.length()-1) | list
    }
    history = function(name,cutoff,_headers){
      html:header("sensor "+name,"",null,null,_headers)
      + <<
<h1>sensor #{name}</h1>
<h2>#{mapping{name}}</h2>
<table>
<tr>
<th>Timestamp</th>
<th>Temperature</th>
</tr>
#{ent:record{name}.pruned_list(cutoff).reduce(temps,"").join("")}
</table>
>>
      + html:footer()
    
    }
    export_tsv = function(){
      one_device = function(list,tabs){
        tts = function(a,tt,i){
          a+(i%2==0 => tt.makeMT().ts_format() + tabs | tt + chr(10))
        }
        list.reduce(tts,"")
      }
      hdr = ["Timestamp"].append(mapping.values().reverse()).join(chr(9))
      lines = mapping.keys().reverse().map(function(k,i){
        tab_char = function(x){chr(9)}
        tabs = 0.range(i).map(tab_char).join("")
        ent:record{k}.one_device(tabs)
      }).join("").split(chr(10)).sort().join(chr(10))
      hdr
      + lines
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
  rule pruneList {
    select when com_vcpnews_wovyn_sensors prune_needed
      where ent:record.keys() >< event:attr("name")
    pre {
      device = event:attr("name")
      cutoff = event:attr("cutoff")
      new_list = ent:record{device}.pruned_list(cutoff)
    }
    fired {
      ent:record{device} := new_list
    }
  }
  rule pruneAllLists {
    select when com_vcpnews_wovyn_sensors prune_all_needed
      cutoff re#^(202\d-\d\d-\d\dT0\d)# setting(cutoff)
    foreach mapping.keys() setting(device)
    pre {
      new_list = ent:record{device}.pruned_list(cutoff)
    }
    fired {
      ent:record{device} := new_list
    }
  }
  rule redirectBack {
    select when com_vcpnews_wovyn_sensors prune_all_needed
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
