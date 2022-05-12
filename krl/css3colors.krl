ruleset css3colors {
  meta {
    provides options, hex2name
  }
  global {
    colormap = {
      }
    options = function(){
      <<<option value="">none</option\>>>
    }
    hex2name = function(hex){
      hexdigits = hex.match(re#^\##) => hex.substr(1) | hex
      re = (hexdigits+"$").as("RegExp")
      colormap.filter(function(v,k){v.match(re)}).head()
    }
  }
}
