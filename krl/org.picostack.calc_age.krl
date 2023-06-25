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
      val_name = ent:name => << value="#{ent:name}">> | ""
      val_year = ent:year => << value="#{ent:year}">> | ""
      html:header("manage age_calcs","",null,null,_headers)
      + <<
<h1>Manage age_calcs</h1>
<form action="#{event_url("new_inputs")}">
  Enter your name: 
  <input name="name" maxlength="80" required#{val_name}>
  <br>
  Enter the year of your birth.
  <input name="year" type="number" maxlength="80" required#{val_year}>
  <br>
  <button type="submit">Submit</button> // was Press any key to continue.
</form>
#{ent:name && ent:age => <<
<p>
#{ent:name}, your age is #{ent:age}.
<a href="#{event_url("inputs_not_needed")}">clear</a>
</p>
>> | ""}
>>
      + html:footer()
    }
    year_installed = time:now().substr(0,4).as("Number") // was 2003
    ageCalc = function(birthYear){
      printf = birthYear.klog("year passed =")
      diff = year_installed - birthYear
      diff
    }
  }
  rule calculateAge {
    select when org_picostack_calc_age new_inputs
      name re#^(.+)$#
      year re#^(\d+)$#
      setting(name,year)
    fired {
      ent:name := name
      ent:year := year
      ent:age := ageCalc(year)
    }
  }
  rule clearInputs {
    select when org_picostack_calc_age inputs_not_needed
    fired {
      clear ent:name
      clear ent:year
      clear ent:age
    }
  }
  rule redirectBack {
    select when org_picostack_calc_age new_inputs
             or org_picostack_calc_age inputs_not_needed
    pre {
      referrer = event:attr("_headers").get("referer") // [sic]
    }
    if referrer then send_directive("_redirect",{"url":referrer})
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
