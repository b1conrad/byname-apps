ruleset org.picostack.calc_age {
  meta {
    name "age_calcs"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares main_url, age_calc
  }
  global {
    event_domain = "org_picostack_calc_age"
    event_url = function(event_type,event_id){
      eid = event_id || "none"
      <<#{meta:host}/sky/event/#{meta:eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(query_name){
      <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/#{query_name}>>
    }
    main_url = function(){
      query_url("age_calc")
    }
    age_calc = function(_headers){
      html:header("manage age_calcs","",null,null,_headers)
      + <<
<h1>Manage age_calcs</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["age_calcs"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise org_picostack_calc_age event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when org_picostack_calc_age factory_reset
    foreach wrangler:channels(["age_calcs"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}