ruleset byu.events {
  meta {
    name "byu_events"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares byu_events, category, byu_event
  }
  global {
    event_domain = "byu_events"
    api_url = "https://calendar.byu.edu/api/Events.json?categories="
    nameFromId = function(id){
      ent:categories.keys().filter(function(k){
        ent:categories{k} >< id
      }).head()
    }
    byu_events = function(_headers){
      html:header("manage byu_events","",null,null,_headers)
      + <<
<h1>Manage byu_events</h1>
<form action="category.html">
<select name="category" required>
<option value="">Choose a category:</option>
#{ent:categories.map(function(v,k){
  <<  <option value="#{v.head()}">#{k}</option>
>>
}).values().join("")}
</select>
<button type="submit">See events</button>
</form>
>>
      + html:footer()
    }
    category = function(category,_headers){
      loggit = (api_url+category).klog("URI")
      response = http:get(api_url+category).klog("response")
      content = response{"content"}.klog("content")
      events = content.decode()
      html:header("see byu events by category","",null,null,_headers)
      + <<
<h1>See BYU events</h1>
<h2>Category: #{nameFromId(category)}</h2>
<dl>
#{events.map(function(v){
  all_day = v{"AllDay"}.decode()
  start_dt = v{"StartDateTime"}
  full_url = v{"FullUrl"}
  <<<dt>#{all_day => start_dt.split(" ").head() | start_dt}</dt>
<dd><a href="#{full_url}">#{v{"Title"}}</a></dd>
>>
}).join("")}</dl>
>>
      + html:footer()
    }
    byu_event = function(event_id,_headers){
      "Not yet implemented"
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["byu_events"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise byu_events event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when byu_events factory_reset
    foreach wrangler:channels(["byu_events"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule inferCategoryIds {
    select when byu_events factory_reset
    pre {
      all_events = http:get(api_url+"all"){"content"}.decode()
      categories = all_events.reduce(function(ans,ev){
          cat_name = ev{"CategoryName"}
          arr = ans.get(cat_name).defaultsTo([])
          ans.put(cat_name,arr.union(ev{"CategoryId"}))
        },ent:categories.defaultsTo({}))
    }
    fired {
      ent:categories := categories
    }
  }
}
