ruleset com.vcpnews.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module html.byu alias html
    shares introspect
  }
  global {
    introspect = function(_headers){
      subs_count = subs:established().length()
      html:header("manage introspections","",null,null,_headers)
      + <<
<h1>Manage introspections</h1>
<h2>Overview</h2>
<p>Your pico is named #{wrangler:name()}</p>
<p>Its parent pico is named #{wrangler:picoQuery(wrangler:parent_eci(),"io.picolabs.wrangler","name")}</p>
<p>It has #{wrangler:installedRIDs().length()} rulesets</p>
<p>It has #{wrangler:channels().length()} channels</p>
<p>It has #{subs_count} subscription#{subs_count==1 => "" | "s"}
These can be managed with the <a href="https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/krl/byu.hr.relate.krl"><code>byu.hr.relate</code> app</a></p>
<h2>Technical</h2>
<button disabled title="not yet implemented">export</button>
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
