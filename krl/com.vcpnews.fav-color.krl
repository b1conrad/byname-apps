ruleset com.vcpnews.fav-color {
  meta {
    name "fav-color"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    // use module css3colors alias colors
    shares index
  }
  global {
    index = function(_headers){
      url = <<#{meta:host}/sky/event/#{meta:eci}/selectcolor/fav_color/fav_color_selected>>
      html:header("Manage Favorite Color","",null,null,_headers)
      + <<
<h1>Manage Favorite Color</h1>
#{ent:colorname => <<<p>Your favorite color:</p>
<table style="background-color:white">
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">RGB hex</th>
      <th scope="col">Swatch</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align:center"><code>#{ent:colorname}</code></td>
      <td><code>#{ent:colorcode}</code></td>
      <td style="background-color:#{ent:colorcode}"></td>
    </tr>
  </tbody>
</table>
>> | <<<p>You have not yet selected a favorite color.</p>
>>}<hr>
<form action="#{url}" method="POST">
Favorite color: <select name="fav_color">
#{options("  ",ent:colorname)}</select>
<button type="submit">Select</button>
</form>
>>
      + html:footer()
    }
// use from colors module when available
    between = function(n,min,max){
      i = n.math:int()
      i < min => min |
      i > max => max |
      i
    }
    as_spaces = function(n){
      n == 0 => "" | 1.range(n).map(function(n){" "}).join("")
    }
    as_margin = function(indent){
      t_i = typeof(indent)
      t_i == "String" => indent |
      t_i == "Number" => indent.between(0,40).as_spaces() |
                         ""
    }
    options = function(indent,default){
      left_margin = indent.as_margin()
      gen_option = function(v,k){
        <<#{left_margin}<option value="#{v}"#{k==default => " selected" | ""}>#{k}</option>
>>
      }
      colormap.map(gen_option).values().join("")
    }
    colormap = {
      "aliceblue": "#f0f8ff",
      "antiquewhite": "#faebd7",
      "aquamarine": "#7fffd4",
      "azure": "#f0ffff",
      "beige": "#f5f5dc",
      "bisque": "#ffe4c4",
      "blanchedalmond": "#ffebcd",
      "blueviolet": "#8a2be2",
      "brown": "#a52a2a",
      "burlywood": "#deb887",
      "cadetblue": "#5f9ea0",
      "chartreuse": "#7fff00",
      "chocolate": "#d2691e",
      "coral": "#ff7f50",
      "cornflowerblue": "#6495ed",
      "cornsilk": "#fff8dc",
      "crimson": "#dc143c",
      "cyan": "#00ffff",
      "darkblue": "#00008b",
      "darkcyan": "#008b8b",
      "darkgoldenrod": "#b8860b",
      "darkgray": "#a9a9a9",
      "darkgreen": "#006400",
      "darkgrey": "#a9a9a9",
      "darkkhaki": "#bdb76b",
      "darkmagenta": "#8b008b",
      "darkolivegreen": "#556b2f",
      "darkorange": "#ff8c00",
      "darkorchid": "#9932cc",
      "darkred": "#8b0000",
      "darksalmon": "#e9967a",
      "darkseagreen": "#8fbc8f",
      "darkslateblue": "#483d8b",
      "darkslategray": "#2f4f4f",
      "darkslategrey": "#2f4f4f",
      "darkturquoise": "#00ced1",
      "darkviolet": "#9400d3",
      "deeppink": "#ff1493",
      "deepskyblue": "#00bfff",
      "dimgray": "#696969",
      "dimgrey": "#696969",
      "dodgerblue": "#1e90ff",
      "firebrick": "#b22222",
      "floralwhite": "#fffaf0",
      "forestgreen": "#228b22",
      "gainsboro": "#dcdcdc",
      "ghostwhite": "#f8f8ff",
      "gold": "#ffd700",
      "goldenrod": "#daa520",
      "greenyellow": "#adff2f",
      "grey": "#808080",
      "honeydew": "#f0fff0",
      "hotpink": "#ff69b4",
      "indianred": "#cd5c5c",
      "indigo": "#4b0082",
      "ivory": "#fffff0",
      "khaki": "#f0e68c",
      "lavender": "#e6e6fa",
      "lavenderblush": "#fff0f5",
      "lawngreen": "#7cfc00",
      "lemonchiffon": "#fffacd",
      "lightblue": "#add8e6",
      "lightcoral": "#f08080",
      "lightcyan": "#e0ffff",
      "lightgoldenrodyellow": "#fafad2",
      "lightgray": "#d3d3d3",
      "lightgreen": "#90ee90",
      "lightgrey": "#d3d3d3",
      "lightpink": "#ffb6c1",
      "lightsalmon": "#ffa07a",
      "lightseagreen": "#20b2aa",
      "lightskyblue": "#87cefa",
      "lightslategray": "#778899",
      "lightslategrey": "#778899",
      "lightsteelblue": "#b0c4de",
      "lightyellow": "#ffffe0",
      "limegreen": "#32cd32",
      "linen": "#faf0e6",
      "magenta": "#ff00ff",
      "mediumaquamarine": "#66cdaa",
      "mediumblue": "#0000cd",
      "mediumorchid": "#ba55d3",
      "mediumpurple": "#9370db",
      "mediumseagreen": "#3cb371",
      "mediumslateblue": "#7b68ee",
      "mediumspringgreen": "#00fa9a",
      "mediumturquoise": "#48d1cc",
      "mediumvioletred": "#c71585",
      "midnightblue": "#191970",
      "mintcream": "#f5fffa",
      "mistyrose": "#ffe4e1",
      "moccasin": "#ffe4b5",
      "navajowhite": "#ffdead",
      "oldlace": "#fdf5e6",
      "olivedrab": "#6b8e23",
      "orangered": "#ff4500",
      "orchid": "#da70d6",
      "palegoldenrod": "#eee8aa",
      "palegreen": "#98fb98",
      "paleturquoise": "#afeeee",
      "palevioletred": "#db7093",
      "papayawhip": "#ffefd5",
      "peachpuff": "#ffdab9",
      "peru": "#cd853f",
      "pink": "#ffc0cb",
      "plum": "#dda0dd",
      "powderblue": "#b0e0e6",
      "rosybrown": "#bc8f8f",
      "royalblue": "#4169e1",
      "saddlebrown": "#8b4513",
      "salmon": "#fa8072",
      "sandybrown": "#f4a460",
      "seagreen": "#2e8b57",
      "seashell": "#fff5ee",
      "sienna": "#a0522d",
      "skyblue": "#87ceeb",
      "slateblue": "#6a5acd",
      "slategray": "#708090",
      "slategrey": "#708090",
      "snow": "#fffafa",
      "springgreen": "#00ff7f",
      "steelblue": "#4682b4",
      "tan": "#d2b48c",
      "thistle": "#d8bfd8",
      "tomato": "#ff6347",
      "turquoise": "#40e0d0",
      "violet": "#ee82ee",
      "wheat": "#f5deb3",
      "whitesmoke": "#f5f5f5",
      "yellowgreen": "#9acd32",
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
  rule recordFavColor {
    select when fav_color fav_color_selected
      fav_color re#^(\#[a-f0-9]{6})$# setting(fav_color)
    pre {
      colorname = colormap.filter(function(v){v==fav_color}).keys().head()
        || "unknown"
    }
    fired {
      ent:colorname := colorname
      ent:colorcode := fav_color
      raise fav_color event "fav_color_recorded" attributes {
        "colorcode":fav_color,
        "colorname":colorname,
      }
    }
  }
  rule redirectBack {
    select when fav_color fav_color_selected
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
