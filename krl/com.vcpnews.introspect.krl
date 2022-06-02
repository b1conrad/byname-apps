ruleset com.vcpnews.introspect {
  meta {
    name "introspections"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    use module html.byu alias html
    shares introspect, rulesets, ruleset
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
    app_url = function(rid){
      rsMeta = wrangler:rulesetMeta(rid)
      home = rsMeta.get("shares").head() + ".html"
      tags = rid == "byu.hr.record" => "record_audio" |
             rid == "byu.hr.manage_apps" => "manage_apps" |
             rsMeta.get("name")
      eci = wrangler:channels(tags).head().get("id") || null
      eci.isnull() => home |
      <<<a href="#{meta:host}/c/#{eci}/query/#{rid}/#{home}">#{home}</a> >>
    }
    pf = re#^file:///usr/local/lib/node_modules/#
    pu = "https://raw.githubusercontent.com/Picolab/pico-engine/master/packages/"
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
<td><a href="#{url}">#{url}</a></td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
>>
      }
      by = function(key){
        function(a,b){a{key}.encode() cmp b{key}.encode()}
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
<td><a href="#{url}">#{url}</a></td>
</tr>
<tr>
<td>Hash</td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
<tr>
<td>Source code hash</td>
<td title="#{source_hash}"#{redden}>#{source_hash.substr(0,7)}</td>
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
}
