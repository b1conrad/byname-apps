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
      baseURL =<<#{meta:host}/sky/event/#{meta:eci}/none/#{event_domain}>> 
      setURL = <<#{baseURL}/new_settings>>
      send_url = <<#{meta:host}/c/#{meta:eci}/event/#{event_domain}/export_file_needed>>
      days_in_record = sensors:daysInRecord()
      one_response = function(v,k){
        <<<dt>#{k}</dt><dd><pre>#{v}</pre></dd>
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
      descr = sensors:export_csv()
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
}
