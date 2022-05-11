ruleset com.vcpnews.fav-color {
  meta {
    name "fav-color"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares index
  }
  global {
    index = function(_headers){
      html:header("Manage Favorite Color","",null,null,_headers)
      + <<
<h1>Manage Favorite Color</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["fav-color"],
        {"allow":[{"domain":"fav_color","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise fav_color event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when fav_color factory_reset
    foreach wrangler:channels("fav-color").reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
