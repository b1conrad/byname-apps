ruleset boilerplate_rs {
  meta {
    name "boilerplates"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares main_url, boilerplate
  }
  global {
    channel_tags = ["boilerplates"]
    event_domain = "boilerplate_rs"
    event_url = function(event_type,event_id){
      eid = event_id || "none"
      <<#{meta:host}/sky/event/#{meta:eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(query_name){
      <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/#{query_name}>>
    }
    main_url = function(){
      query_url("boilerplate.html")
    }
    boilerplate = function(_headers){
      html:header("manage boilerplates","",null,null,_headers)
      + <<
<h1>Manage boilerplates</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        channel_tags,
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise boilerplate_rs event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when boilerplate_rs factory_reset
    foreach wrangler:channels(channel_tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
