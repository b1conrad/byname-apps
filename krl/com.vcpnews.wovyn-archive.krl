ruleset com.vcpnews.wovyn-archive {
  meta {
    name "responses"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    use module com.vcpnews.wovyn-sensors alias sensors
    use module com.mailjet.sdk alias email
    shares response
  }
  global {
    event_domain = "com_vcpnews_wovyn_archive"
    response = function(_headers){
      base_url = <<#{meta:host}/sky/event/#{meta:eci}>>
      setURL = <<#{base_url}/set/#{event_domain}/new_settings>>
      morning_url_on = <<#{base_url}/activate/#{event_domain}/morning_notification_wanted>>
      morning_url_off = <<#{base_url}/deactivate/#{event_domain}/no_morning_notification>>
      is_morning_event = function(s){
                           s{["event","domain"]} == event_domain &&
                           s{["event","name"]} == "it_is_morning"
                         }
      morning_event = schedule:list().filter(is_morning_event).head()
      toggle_url = morning_event => morning_url_off+"?id="+morning_event{"id"} | morning_url_on
      toggle_label = morning_event => "Turn off" | "Turn on"
      send_url = <<#{meta:host}/c/#{meta:eci}/event/#{event_domain}/export_file_needed>>
      days_in_record = sensors:daysInRecord()
      one_response = function(v,k){
        resp = v.encode()
        <<<dt>#{k}</dt><dd><pre>#{resp}</pre></dd>
>>
      }
      html:header("manage responses","",null,null,_headers)
      + <<
<h1>Manage responses</h1>
<h2>Responses</h2>
<dl>#{ent:responses.map(one_response).values().join("")}</dl>
<h2>Setup</h2>
<h3>Email Setup</h3>
<form action="#{setURL}">
To <input name="email" value="#{ent:email || ""}">
<button type="submit">Save changes</button>
</form>
<h3>Morning notification</h3>
<h4>Active?</h4>
<p>#{
  morning_event => "Yes" | "No"
}
<button onclick="location='#{toggle_url}'">#{toggle_label}</button>
</p>
<h2>Technical</h2>
<h3>Days in record</h3>
<ul>
#{days_in_record.sort().map(function(d,i){
  url = send_url + "?date=" + d
  item = i => d | <<<a href="#{url}">#{d}</a\>>>
  <<  <li>#{item}</li>
>>}).join("")}</ul>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["responses"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise com_vcpnews_wovyn_archive event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when com_vcpnews_wovyn_archive factory_reset
    foreach wrangler:channels(["responses"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule saveSettings {
    select when com_vcpnews_wovyn_archive new_settings
      email re#(.+@.+)# setting(to)
    if ent:email != to then noop()
    fired {
      ent:email := to
      ent:responses := {}
    }
  }
  rule sendExportViaEmail {
    select when com_vcpnews_wovyn_archive export_file_needed
      date re#^(202\d-\d\d-\d\d)$# setting(date)
    pre {
      subject = <<ByName: #{meta:rid}: #{date}>>
      dateRE = ("^"+date).as("RegExp")
      current_date = function(entry,index){
        index == 0              // keep header line
        || entry.match(dateRE)  // and entries for this date
      }
      descr = sensors:export_csv().filter(current_date)
    }
    if ent:email then
      email:send_text(ent:email,subject,descr) setting(response)
    fired {
      ent:responses{date} := response
    }
  }
  rule redirectBack {
    select when com_vcpnews_wovyn_archive new_settings
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
  rule dailyExportAndPrune {
    select when com_vcpnews_wovyn_archive it_is_morning
    pre {
      days_in_record = sensors:daysInRecord()
    }
    if days_in_record.length() >= 2 then noop()
    fired {
      raise com_vcpnews_wovyn_archive event "export_file_needed"
        attributes {"date":days_in_record.head()}
      raise com_vcpnews_wovyn_sensors event "prune_all_needed"
        attributes {"cutoff":days_in_record[1]+"T06"}
    }
  }
  rule activateMorningNotification {
    select when com_vcpnews_wovyn_archive morning_notification_wanted
    fired {
      schedule com_vcpnews_wovyn_archive event "it_is_morning"
        repeat << 0 9 * * * >>  attributes { } setting(id)
      ent:id := id
    }
  }
  rule deactivateMorningNotification {
    select when com_vcpnews_wovyn_archive no_morning_notification
      id re#(.+)# setting(id)
    schedule:remove(id)
    fired {
      clear ent:id if ent:id == id || ent:id{"id"} == id
    }
  }
}
