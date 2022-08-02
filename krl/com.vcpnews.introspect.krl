ruleset com.vcpnews.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module html.byu alias html
    shares introspect, channels, channel, subscriptions, subscription
    provides app_url
  }
  global {
    rsRID = "com.vcpnews.ruleset"
    introspect = function(_headers){
      subs_count = subs:established()
        .filter(function(s){s{"Tx_role"}!="participant list"})
        .length()
      pECI = wrangler:parent_eci()
      pName = pECI.isnull() => null | wrangler:picoQuery(pECI,"io.picolabs.wrangler","name")
      apps = html:cookies(_headers){"apps"}.split(",")
      rs_link = <<<a href="../com.vcpnews.ruleset/rulesets.html">rulesets</a\>>>
      cs_link = <<<a href="channels.html">channels</a\>>>
      ss_link = <<#{subs_count} <a href="subscriptions.html">subscription#{subs_count==1 => "" | "s"}</a\>>>
      child_count = wrangler:children().length()
      one_child = wrangler:children().head()
      child_eci = one_child{"eci"}
      html:header("manage introspections","",null,null,_headers)
      + <<
<h1>Manage introspections</h1>
<h2>Overview</h2>
<p>Your pico is named #{wrangler:name()}#{
  pName => << and its parent pico is named #{pName}.>> | "."}</p>
<p>It has #{wrangler:installedRIDs().length()} #{rs_link},
of which #{apps.length()} are apps.
The apps can be managed with #{app_url("byu.hr.manage_apps")}.</p>
<p>It has #{wrangler:channels().length()} #{cs_link}.</p>
<p>It has #{subs_count => ss_link | "no subscriptions"}.
These can be managed with #{app_url("byu.hr.relate")}.</p>
<p>
It has #{child_count} child pico#{
  one_child => <<: #{one_child{"name"}}
<a href="#{meta:host}/sky/event/#{meta:eci}/none/ruleset/child_pico_not_needed?eci=#{child_eci}">del</a>.
>> | "s."
}
</p>
<h2>Technical</h2>
<button disabled title="not yet implemented">export</button>
>>
      + html:footer()
    }
    app_url = function(rid){
      rsMeta = wrangler:rulesetMeta(rid)
      home = rsMeta.get("shares").head() + ".html"
      tags = rid == "byu.hr.record" => "record_audio" |
             rid == "byu.hr.manage_apps" => "manage_apps" |
             rsMeta.get("name")
      eci = wrangler:channels(tags).head().get("id") || null
      eci.isnull() => home |
      <<<a href="#{meta:host}/c/#{eci}/query/#{rid}/#{home}">#{home}</a\>>>
    }
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    channels = function(_headers){
      cs = wrangler:channels()
        .filter(function(c){c{"familyChannelPicoID"}.isnull()})
      one_channel = function(c){
        <<<tr>
<td><a href="channel.html?eci=#{c{"id"}}"><code>#{c{"id"}}</code></a></td>
<td>#{c{"tags"}.join(", ")}</td>
</tr>
>>
      }
      html:header("Your channels","",null,null,_headers)
      + <<<h1>Your channels</h1>
<table>
<tr>
<td>ECI</td>
<td>tags</td>
</tr>
#{cs.sort(by("id")).map(one_channel).join("")}</table>
>>
      + html:footer()
    }
    channel = function(eci,_headers){
      this_c = wrangler:channels()
        .filter(function(c){c{"id"}==eci})
        .head()
      html:header(eci,"",null,null,_headers)
      + <<<h1>Your <code>#{eci}</code> channel</h1>
<table>
<tr>
<td>ECI</td>
<td><code>#{this_c{"id"}}</code></td>
</tr>
<td>tags</td>
<td>#{this_c{"tags"}.join(", ")}</td>
</tr>
<tr>
<td>raw</td>
<td>#{this_c.encode()}</td>
</tr>
</table>
>>
      + html:footer()
    }
    participant_name = function(eci){
      thisPico = ctx:channels.any(function(c){c{"id"}==eci})
      thisPico => "yourself" | ctx:query(eci,"byu.hr.core","displayName")
    }
    subs_tags = function(s){
      wrangler:channels()
        .filter(function(c){c{"id"}==s{"Rx"}})
        .head()
        {"tags"}.join(", ")
    }
    subscriptions = function(_headers){
      ss = subs:established()
        .filter(function(s){s{"Tx_role"}!="participant list"})
      one_subs = function(s){
        <<<tr>
<td><a href="subscription.html?Id=#{s{"Id"}}"><code>#{s{"Id"}}</code></a></td>
<td>#{s{"Rx_role"}}</td>
<td>#{s{"Tx_role"}}</td>
<td>#{s{"Tx"}.participant_name()}</td>
<td>#{subs_tags(s)}</td>
</tr>
>>
      }
      html:header("Your subscriptions","",null,null,_headers)
      + <<<h1>Your subscriptions</h1>
<table>
<tr>
<td>Id</td>
<td>your role</td>
<td>their role</td>
<td>with</td>
<td>channel tags</td>
</tr>
#{ss.sort(by("Id")).map(one_subs).join("")}</table>
>>
      + html:footer()
    }
    subscription = function(_headers,Id){
      this_s = subs:established("Id",Id).head()
      Rx = this_s{"Rx"}
      html:header(Id,"",null,null,_headers)
      + <<<h1>Your <code>#{Id}</code> subscription</h1>
<table>
<tr>
<td>Id</td>
<td><code>#{this_s{"Id"}}</code></td>
</tr>
<tr>
<td>your channel</td>
<td><a href="channel.html?eci=#{Rx}"><code>#{Rx}</code></a></td>
</tr>
<tr>
<td>their channel</td>
<td><code>#{this_s{"Tx"}}</code></td>
</tr>
<tr>
<td>your role</td>
<td>#{this_s{"Rx_role"}}</td>
</tr>
<tr>
<td>their role</td>
<td>#{this_s{"Tx_role"}}</td>
</tr>
</tr>
<td>with</td>
<td>#{this_s{"Tx"}.participant_name()}</td>
</tr>
<tr>
<td>channel tags</td>
<td>#{subs_tags(this_s)}</td>
</tr>
</table>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["introspections"],
        {"allow":[{"domain":"introspect","name":"*"},
                  {"domain":"ruleset","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"},
                  {"rid":rsRID,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise introspect event "channel_created"
      raise wrangler event "install_ruleset_request" attributes {
        "absoluteURL":meta:rulesetURI,"rid":rsRID,
      }
    }
  }
  rule keepChannelsClean {
    select when introspect channel_created
    foreach wrangler:channels("introspections").reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
