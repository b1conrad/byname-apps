ruleset com.vcpnews.wovyn-archive {
  meta {
    name "responses"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    use module com.vcpnews.wovyn-sensors alias wovyn
    shares response
  }
  global {
    event_domain = "com_vcpnews_wovyn_archive"
    response = function(_headers){
      send_url = <<#{meta:host}/c/#{meta:eci}/event/#{event_domain}/export_file_needed>>
      days_in_record = wovyn:daysInRecord()
      html:header("manage responses","",null,null,_headers)
      + <<
<h1>Manage responses</h1>
<h3>Email Setup</h3>
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
  rule sendExportViaEmail {
    select when com_vcpnews_wovyn_archive export_file_needed
      date re#^(202\d-\d\d-\d\d)$# setting(date)
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":date,
        "description":wovyn:export_csv()
      }
    }
  }
}
