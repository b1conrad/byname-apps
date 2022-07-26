ruleset com.vcpnews.editor {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares krl
  }
  global {
    krl = function(rid){
      <<ruleset #{rid} {
}
>>
    }
  }
}
