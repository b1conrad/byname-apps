ruleset com.vcpnews.editor {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares krl, pico_eci
  }
  global {
    krl = function(rid){
      ent:src
    }
    pico_eci = function(){
      ent:eci
    }
    event_domain = "introspect_editor"
    tags = ["introspect","editor"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      ) setting(channel)
    }
    fired {
      raise introspect_editor event "channel_created"
      ent:src := event:attr("src").math:base64decode()
      ent:eci := channel{"id"}
    }
  }
  rule keepChannelsClean {
    select when introspect_editor channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
