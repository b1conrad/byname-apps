ruleset my.special.guessing-app {
  meta {
    name "guesses"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares guess
  }
  global {
    guess = function(_headers){
      html:header("manage guess","",null,null,_headers)
      + <<
<h1>Manage guess</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["my-special-guessing-app","guess"],
        {"allow":[{"domain":"guessing_app","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise guessing_app event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when guessing_app factory_reset
    foreach wrangler:channels(["my-special-guessing-app","guess"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}