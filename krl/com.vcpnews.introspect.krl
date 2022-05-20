ruleset com.vcpnews.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module html.byu alias html
    shares introspect, rulesets
  }
  global {
    introspect = function(_headers){
      subs_count = subs:established().length()
      relateURL = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/krl/byu.hr.relate.krl"
      manage_appsURL = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/krl/byu.hr.manage_apps.krl"
      pECI = wrangler:parent_eci()
      pName = pECI.isnull() => null | wrangler:picoQuery(pECI,"io.picolabs.wrangler","name")
      apps = html:cookies(_headers){"apps"}.split(",")
      rs_link = <<<a href="rulesets.html">rulesets</a\>>>
      html:header("manage introspections","",null,null,_headers)
      + <<
<h1>Manage introspections</h1>
<h2>Overview</h2>
<p>Your pico is named #{wrangler:name()}#{
  pName => << and its parent pico is named #{pName}.>> | "."}</p>
<p>It has #{wrangler:installedRIDs().length()} #{rs_link}#{
  apps.length() => <<, of which #{apps.length()} are apps.
These can be managed with the <a href="#{manage_appsURL}"><code>byu.hr.manage_apps</code></a> app.>> | "."}</p>
<p>It has #{wrangler:channels().length()} channels.</p>
<p>It has #{subs_count} subscription#{subs_count==1 => "" | "s"}.
These can be managed with the <a href="#{relateURL}"><code>byu.hr.relate</code></a> app.</p>
<h2>Technical</h2>
<button disabled title="not yet implemented">export</button>
>>
      + html:footer()
    }
    rulesets = function(_headers){
      apps = html:cookies(_headers){"apps"}.split(",")
      pf = re#^file:///usr/local/lib/node_modules/#
      pu = "https://raw.githubusercontent.com/Picolab/pico-engine/master/packages/"
      sort_key = ["meta","flushed"]
      one_ruleset = function(rs){
        rid = rs{"rid"}
        flushed_time = rs{sort_key}
debug = typeof(flushed_time) == "Map" => flushed_time.keys().klog("debug") | ""
        url = rs{"url"}.replace(pf,pu)
        <<<tr>
<td>#{rid}</td>
<td>#{apps >< rid => "app" | ""}</td>
<td>#{flushed_time.makeMT().ts_format()}</td>
<td><a href="#{url}">#{url}</a></td>
</tr>
>>
      }
      by = function(key){
        function(a,b){a{key} cmp b{key}}
      }
      html:header("Your rulesets","",null,null,_headers)
      + <<<h1>Your rulesets</h1>
<table>
#{ctx:rulesets.sort(by(sort_key)).map(one_ruleset).join("")}</table>
>>
      + html:footer()
    }
    makeMT = function(ts){
      to = ts.typeof()
      tts = to == "String" => ts |
            to == "Map" => ts.encode().decode() |
            ts
      MST = time:add(tts,{"hours": -7});
      MDT = time:add(tts,{"hours": -6});
      MDT > "2022-11-06T02" => MST |
      MST > "2022-03-13T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["introspections"],
        {"allow":[{"domain":"introspect","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise introspect event "channel_created"
    }
  }
  rule keepChannelsClean {
    select when introspect channel_created
    foreach wrangler:channels("introspections").reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
