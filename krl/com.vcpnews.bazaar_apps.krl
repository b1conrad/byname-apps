ruleset com.vcpnews.bazaar_apps {
  meta {
    name "bazaar_apps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares bazaar, krl_code
  }
  global {
    bazaar = function(_headers){
      html:header("manage bazaar apps","",null,null,_headers)
      + <<
<h1>Manage bazaar apps</h1>
>>
      + html:footer()
    }
    tags = ["bazaar_apps"]
    krl_code = function(rid){
      rsname = ent:apps{[rid,"rsname"]}
      home = ent:apps{[rid,"name"]}
      channel_tags = [
        rid.replace(re#[.]#g,"-"),
        ent:apps{[rid,"name"]}
      ].encode()
      event_domain = ent:apps{[rid,"event_domain"]}
      <<ruleset #{rid} {
  meta {
    name "#{rsname}"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares #{home}
  }
  global {
    #{home} = function(_headers){
      html:header("manage #{home}","",null,null,_headers)
      + <<
<h1>Manage #{home}</h1>
/>/>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        #{channel_tags},
        {"allow":[{"domain":"#{event_domain}","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise #{event_domain} event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when #{event_domain} factory_reset
    foreach wrangler:channels(#{channel_tags}).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
>>
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":"bazaar_apps","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise bazaar_apps event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when bazaar_apps factory_reset
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule acceptNewApp {
    select when bazaar_apps new_app
      rid re#^(.+)$#
      home re#^(.+)$#
      rsname re#(.*)#
      event_domain re#(.*)#
      setting(rid,home,rsname,event_domain)
    pre {
      spec = {
        "rid": rid,
        "name": home,
        "rsname": rsname || home,
        "event_domain": event_domain || rid.replace(re#[.-]#g,"_")
      }
    }
    fired {
      ent:apps{rid} := spec
    }
  }
}
