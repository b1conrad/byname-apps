ruleset boilerplate {
  meta {
    name "boilerplates"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares boilerplate
  }
  global {
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
        ["boilerplates"],
        {"allow":[{"domain":"boilerplate","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise boilerplate event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when boilerplate factory_reset
    foreach wrangler:channels("boilerplates").reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
