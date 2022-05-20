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
      one_ruleset = function(rs){
        <<<li>#{rs{"rid"}}: #{rs{"flushed"}}</li>
>>
      }
      by = function(key){
        function(a,b){a{key} cmp b{key}}
      }
      by_flushed = function(a,b){
        a{"flushed"} cmp b{"flushed"}
      }
      html:header("Your rulesets","",null,null,_headers)
      + <<<h1>Your rulesets</h1>
<ul>
#{ctx:rulesets.sort(by_flushed).map(one_ruleset).join("")}</ul>
>>
      + html:footer()
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
