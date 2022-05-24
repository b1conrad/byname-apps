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
      sort_key = ["meta","flushed"]
      one_ruleset = function(rs){
        rid = rs{"rid"}
        flushed_time = rs{sort_key}
        url = rs{"url"}.replace(pf,pu)
        meta_hash = rs{["meta","hash"]}
        <<<tr>
<td>#{rid}</td>
<td>#{apps >< rid => app_url(rid) | ""}</td>
<td>#{flushed_time.makeMT().ts_format()}</td>
<td><a href="#{url}">#{url}</a></td>
<td title="#{meta_hash}">#{meta_hash.substr(0,7)}</td>
</tr>
>>
      }
      by = function(key){
        function(a,b){a{key} cmp b{key}}
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
      + module_usage().encode()
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
    modules_used = function(){
      // a Map of Arrays; key is using RID; value is array of modules used
      make_list = function(an_array,module_usage){
        an_array.append(module_usage{"rid"})
      }
      find_usages = function(a_map,rs){
        rid = rs{"rid"}
.klog("rid")
        uses = wrangler:rulesetMeta(rid){"use"} // an Array of Maps
          .defaultsTo([])
          .filter(function(v){v{"kind"}=="module"})
          .reduce(make_list,[]) // an Array of Strings
.klog("uses")
        a_map.put(rid,uses)
      }
      ctx:rulesets // an Array of Maps
        .reduce(find_usages,{})
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
