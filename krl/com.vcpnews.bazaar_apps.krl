ruleset com.vcpnews.bazaar_apps {
  meta {
    name "bazaar_apps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares bazaar, krl_code
  }
  global {
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
table input {
  width: 90%;
}
</style>
>>
    bazaar = function(_headers){
      base = <<#{meta:host}/sky/cloud/#{meta:eci}/#{meta:rid}/krl_code.txt>>
      li_apps = function(){
        ent:apps
          .values()
          .map(function(spec){
            rid = spec{"rid"}
            <<<tr>
<td><code>#{rid}</code></td>
<td>#{spec.get("name")}</td>
<td>#{spec.get("rsname")}</td>
<td>#{spec.get("event_domain")}</td>
<td><a href="#{base}?rid=#{rid}" target="_blank">make KRL</a></td>
</tr>
>>
          })
      }
      html:header("manage bazaar apps",styles,null,null,_headers)
      + <<
<h1>Manage bazaar apps</h1>
<h2>Apps</h2>
<table>
<tr>
<th>RID</th>
<th>name</th>
<th>rsname</th>
<th>event domain</th>
<th>boilerplate</th>
</tr>
#{li_apps().join("")}</table>
<h2>New app</h2>
<form action="#{meta:host}/sky/event/#{meta:eci}/none/bazaar_apps/new_app">
<input name="rid" placeholder="RID"> e.x. my.special.guessing-app<br>
<input name="home" placeholder="homepage"> e.x. guess<br>
<input name="rsname" placeholder="rsname"> e.x. guesses<br>
<input name="event_domain" placeholder="event_domain"> e.x. guessing_app<br>
<button type="submit">Submit</button>
</form>
>>
      + html:footer()
    }
    tags = ["bazaar_apps"]
    krl_code = function(rid){
      rsname = ent:apps{[rid,"rsname"]}
      home = ent:apps{[rid,"name"]}
      channel_tags = [ent:apps{[rid,"rsname"]}].encode()
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
      html:header("manage #{rsname}","",null,null,_headers)
      + <<
<h1>Manage #{rsname}</h1>
\>\>
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
  rule redirectBack {
    select when bazaar_apps new_app
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
