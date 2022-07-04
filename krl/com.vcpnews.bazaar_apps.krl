ruleset com.vcpnews.bazaar_apps {
  meta {
    name "bazaar_apps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares bazaar
  }
  global {
    bazaar = function(_headers){
      html:header("manage bazaar apps","",null,null,_headers)
      + <<
<h1>Manage bazaar apps</h1>
>>
      + html:footer()
    }
    tags = ["bazaar_apps"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":"bazaar_apps","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise bazaar_apps event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when bazaar_apps factory_reset
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
