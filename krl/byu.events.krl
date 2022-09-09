ruleset byu.events {
  meta {
    name "byu_events"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares categories, category
  }
  global {
    event_domain = "byu_events"
    api_url = "https://calendar.byu.edu/api/Events.json?categories="
    nameFromId = function(id){
      ent:categories.keys().filter(function(k){
        ent:categories{k} >< id
      }).head()
    }
    categories = function(_headers){
      html:header("select from categories","",null,null,_headers)
      + <<
<h1>Select from categories</h1>
<form action="category.html">
<select name="category_id" required>
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
    category = function(category_id,_headers){
      events = http:get(api_url+category_id){"content"}.decode()
      html:header("byu events by category","",null,null,_headers)
      + <<
<h1>BYU events</h1>
<h2>Category: #{nameFromId(category_id)}</h2>
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
      accumulate = function(ans,ev){
        cat_name = ev{"CategoryName"}
        arr = ans.get(cat_name).defaultsTo([])
        ans.put(cat_name,arr.union(ev{"CategoryId"}))
      }
      starting_with = ent:categories.defaultsTo({})
      categories = all_events.reduce(accumulate,starting_with)
    }
    fired {
      ent:categories := categories
    }
  }
}
