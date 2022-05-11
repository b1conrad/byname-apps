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
#{ent:colorname => <<<p>Your favorite color:</p>
<table>
<tr>
<td style="text-align:center"><code>#{ent:colorname}</code></td>
<td><code>#{ent:colorcode}</code></td>
<td style="background-color:#{ent:colorname}"></td>
</tr>
</table>
>> | ""}<hr>
<form>
Favorite color: <select name="fav_color">
</select>
<br>
<button type="submit">Submit</button>
</form>
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
  rule initialValues {
    select when fav_color factory_reset
    fired {
      ent:colorname := "wheat"
      ent:colorcode := "#f5deb3"
    }
  }
}
