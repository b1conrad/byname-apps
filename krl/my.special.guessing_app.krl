ruleset my.special.guessing-app {
  meta {
    name "guesses"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares guess
  }
  global {
    guess = function(_headers){
      html:header("manage guesses","",null,null,_headers)
      + <<
<h1>Manage guesses</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["guesses"],
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
    foreach wrangler:channels(["guesses"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
