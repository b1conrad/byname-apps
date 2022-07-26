ruleset com.vcpnews.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module html.byu alias html
    shares introspect, rulesets, ruleset, channels, channel, subscriptions, subscription
  }
  global {
    introspect = function(_headers){
      subs_count = subs:established()
        .filter(function(s){s{"Tx_role"}!="participant list"})
        .length()
      pECI = wrangler:parent_eci()
      pName = pECI.isnull() => null | wrangler:picoQuery(pECI,"io.picolabs.wrangler","name")
      apps = html:cookies(_headers){"apps"}.split(",")
      rs_link = <<<a href="rulesets.html">rulesets</a\>>>
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
<a href="#{meta:host}/sky/event/#{meta:eci}/none/introspect/child_pico_not_needed?eci=#{child_eci}">del</a>.
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
    pf = re#^file:///usr/local/lib/node_modules/#
    pu = "https://raw.githubusercontent.com/Picolab/pico-engine/master/packages/"
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    rulesets = function(_headers){
      xref = module_usage()
      deet = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/ruleset.html?rid=>>
      apps = html:cookies(_headers){"apps"}.split(",")
      sort_key = ["meta","flushed"]
      one_ruleset = function(rs){
        rid = rs{"rid"}
        module_xref = xref{rid}
        module_title = module_xref.length()==0 => ""
          | << title="used as module by #{module_xref.join(", ")}">>
        flushed_time = rs{sort_key}
          .encode().decode() // work around issue #602
        url = rs{"url"}.replace(pf,pu)
        meta_hash = rs{["meta","hash"]}
        <<<tr>
<td#{module_title}><a href="#{deet+rid}">#{rid}</a></td>
<td>#{apps >< rid => app_url(rid) | ""}</td>
<td title="#{flushed_time}">#{flushed_time.makeMT().ts_format()}</td>
<td><a href="#{url}" target="_blank">#{url}</a></td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
>>
      }
      html:header("Your rulesets","",null,null,_headers)
      + <<<h1>Your rulesets</h1>
<table>
<tr>
<td>Ruleset ID</td>
<td>App</td>
<td>Last flushed</td>
<td>Source code</td>
<td>Hash</td>
</tr>
#{ctx:rulesets.sort(by(sort_key)).map(one_ruleset).join("")}</table>
>>
      + html:footer()
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
    r_use_m_relation = function(){ // a set (an Array) of ordered pairs
      add_relations = function(set,rs){
        rid = rs{"rid"}
        ops = rs{["meta","krlMeta","use"]}
          .defaultsTo([])
          .filter(function(v){v{"kind"}=="module"})
          .map(function(u){[rid,u{"rid"}]})
        set.append(ops)
      }
      ctx:rulesets
        .reduce(add_relations,[])
    }
    module_usage = function(){
      xref = function(amap,op){
        r = op.head()
        m = op[1]
        amap.put(m,amap.get(m).defaultsTo([]).append(r))
      }
      r_use_m_relation() // set of (rid,module) ordered pairs
        .reduce(xref,{})
    }
    ruleset = function(rid,_headers){
      apps = html:cookies(_headers){"apps"}.split(",")
      rs = ctx:rulesets.filter(function(r){r{"rid"}==rid}).head()
      xref = module_usage()
      module_xref = xref{rid}
      exclude = function(x){function(v){v != x}}
      flushed_time = rs{["meta","flushed"]}
        .encode().decode() // work around issue #602
      url = rs{"url"}.replace(pf,pu)
      meta_hash = rs{["meta","hash"]}
      source_krl = http:get(url){"content"}
      source_hash = math:hash("sha256",source_krl)
      redden = source_hash == meta_hash => ""
                                         | << style="color:red">>
      editURL = <<#{meta:host}/sky/event/#{meta:eci}/none/introspect/app_needs_edit>>
      editable_app = rid != "byu.hr.record" && rid != "byu.hr.manage_apps"
      html:header(rid,"",null,null,_headers)
      + <<<h1>Your ruleset <code>#{rid}</code></h1>
<table>
<tr>
<td>RID</td>
<td>#{rid}</td>
</tr>
<tr>
<td>Provides</td>
<td>#{rs{["meta","krlMeta","provides"]}
       .defaultsTo(["nothing"])
       .join(", ")
     }</td>
</tr>
<tr>
<td>Used as module</td>
<td>#{module_xref.length()==0 => "No" | module_xref.join(", ")}</td>
</tr>
<tr>
<td>Shares</td>
<td>#{rs{["meta","krlMeta","shares"]}
        .defaultsTo([])
        .filter(exclude("__testing"))
        .join(", ")
     }</td>
</tr>
<tr>
<td>App</td>
<td>#{apps >< rid => app_url(rid) | "No"}</td>
</tr>
<tr>
<td>Last flushed</td>
<td title="#{flushed_time}">#{flushed_time.makeMT().ts_format()}</td>
</tr>
<tr>
<td>Source code</td>
<td><a href="#{url}" target="_blank">#{url}</a></td>
</tr>
<tr>
<td>Internal hash</td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
<tr>
<td>Source code hash</td>
<td title="#{source_hash}"#{redden}>#{source_hash.substr(0,7)}</td>
</tr>
</table>
>>
      + (apps >< rid => <<
<br>
<form action="#{editURL}">
<input type="hidden" name="src" value="#{rs{["meta","krl"]}.math:base64encode()}">
<button type="submit"#{editable_app => "" | << disabled title="not editable">>}>Edit app KRL</button>
</form>
>> | "")
      + html:footer()
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
  rule createEditorChildIfNeeded {
    select when introspect app_needs_edit
      src re#(.+)# setting(src)
    pre {
      children = wrangler:children()
      netid = wrangler:name()
      editor_name = netid+"/bazaar"
      editor = children
        .filter(function(c){
          c{"name"} == editor_name
        })
        .head()
      editor_rid = "com.vcpnews.editor"
      eci = function(){
        editor => wrangler:picoQuery(editor{"eci"}.klog("eci"),editor_rid,"pico_eci") | null
      }
      url = <<#{meta:host}/sky/query/#{eci()}/#{editor_rid}/krl.txt>>
    }
    if editor then // noop() // send it an edit event
      send_directive("_redirect",{"url":url})
    fired {
    }
    else {
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",editor_name)
    }
  }
  rule openNewEditor {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
        .klog("child_eci")
      editor_rid = "com.vcpnews.editor"
    }
    if child_eci then
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":event:attrs.put(
          {"absoluteURL": meta:rulesetURI,"rid":editor_rid}
        )
      })
    fired {
      raise introspect event "editor_installed" // redirect to editor
    }
  }
  rule deleteChildPico {
    select when introspect child_pico_not_needed
      eci re#(.+)# setting(eci)
    pre {
      referrer = event:attr("_headers").get("referer") // [sic]
    }
    send_directive("_redirect",{"url":referrer})
    fired {
      raise wrangler event "child_deletion_request" attributes {"eci":eci}
    }
  }
}
