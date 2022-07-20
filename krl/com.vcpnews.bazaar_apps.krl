ruleset com.vcpnews.bazaar_apps {
  meta {
    name "bazaar_apps"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares bazaar, krl_code
  }
  global {
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
input:invalid {
  border-color: red;
}
</style>
>>
    bazaar = function(_headers){
      base = <<#{meta:host}/sky/cloud/#{meta:eci}/#{meta:rid}/krl_code.txt>>
      li_apps = function(){
        ent:apps
          .values()
          .map(function(spec){
            rid = spec{"rid"}
            <<<tr>
<td><code>#{rid}</code></td>
<td><code>#{spec.get("name")}</code></td>
<td><code>#{spec.get("rsname")}</code></td>
<td><code>#{spec.get("event_domain")}</code></td>
<td><a href="#{base}?rid=#{rid}" onclick="shwk(event);return false">make KRL</a></td>
<td><a href="#{meta:host}/sky/event/#{meta:eci}/none/bazaar_apps/app_not_wanted?rid=#{rid}" onclick="return confirm('This cannot be undone, and the app may be lost if you proceed.')">del</a></td>
</tr>
>>
          })
      }
      html:header("manage bazaar apps",styles,null,null,_headers)
      + <<
<h1>Manage bazaar apps</h1>
<h2>Apps</h2>
<table>
<tr>
<th>Ruleset ID</th>
<th>App Name</th>
<th>App meta name</th>
<th>event domain</th>
<th>boilerplate</th>
<th>Delete</th>
</tr>
#{li_apps().join("")}</table>
<h2>New app</h2>
<form action="#{meta:host}/sky/event/#{meta:eci}/none/bazaar_apps/new_app">
<input name="rid" placeholder="Ruleset ID" onchange="this.form.event_domain.value=this.value.replace(/[.-]/g,'_')" required size="40" pattern="[a-zA-Z][a-zA-Z0-9._-]+">
e.x. my.special.guessing-app
[start with a letter; may contain letters, digits, underscores, dashes, and periods]
<br>
<input name="home" placeholder="App Name" required size="40" pattern="[a-zA-Z][a-zA-Z0-9_]+">
e.x. guess
[start with a letter; may contain letters, digits, and underscores]
<br>
<input name="rsname" placeholder="App meta name" required size="40" pattern="[a-zA-Z][a-zA-Z0-9_]+">
e.x. guesses
[start with a letter; may contain letters, digits, and underscores]
<br>
<input name="event_domain" readonly size="40" title="read-only">
(computed from RID)
<br>
<button type="submit">Submit</button>
</form>
<style>
#modal {
  background-color: #F1F0EC;
  position: fixed; top: 50%; left: 50%;
  transform: translate(-50%,-50%) scale(0);
  width: 800px; max-width: 80%;
  border: 1px solid black; border-radius: 10px;
  transition: 300ms ease-in-out;
}
#modal.active {
  transform: translate(-50%,-50%) scale(1);
}
#modal-close {
  float: right; cursor: pointer;
  border: none; background: none;
  font-size: 1.25rem; font-weight: bold;
}
#modal-pre {
  overflow: overlay;
  padding: 0 5px;
  background-color: #F1F0EC;
}
#shadow {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background-color: rgba(0,0,0,.5); opacity: 0;
  pointer-events: none;
  transition: 300ms ease-in-out;
}
#shadow.active {
  opacity: 0.5;
  pointer-events: all;
}
</style>
<div id="shadow" onclick="clearModal()"></div>
<div id="modal">
  <button id="modal-close" onclick="clearModal()">&times;</button>
  <pre id="modal-pre"></pre>
</div>

<script type="text/javascript">
const the_modal_pre = document.getElementById('modal-pre');
const the_modal = document.getElementById('modal');
const the_shadow = document.getElementById('shadow');
function shwk(event){
  var xhr = new XMLHttpRequest;
  xhr.onload = function(){
    var data = xhr.response;
    if(data && data.length){
      the_modal_pre.textContent = data;
      the_modal.classList.add('active');
      the_shadow.classList.add('active');
    }
  }
  xhr.onerror = function(){alert(xhr.responseText);}
  xhr.open("GET",event.target.href,true);
  xhr.send();
}
function clearModal(){
  the_shadow.classList.remove('active');
  the_modal.classList.remove('active');
}
</script>
>>
      + html:footer()
    }
    tags = ["bazaar_apps"]
    krl_code = function(rid){
      rsname = ent:apps{[rid,"rsname"]}
      home = ent:apps{[rid,"name"]}
      channel_tags = [ent:apps{[rid,"rsname"]}].encode()
      event_domain = ent:apps{[rid,"event_domain"]}
      <<ruleset #{rid} {
  meta {
    name "#{rsname}"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares #{home}
  }
  global {
    event_domain = "#{event_domain}"
    #{home} = function(_headers){
      html:header("manage #{rsname}","",null,null,_headers)
      + <<
<h1>Manage #{rsname}</h1>
\>\>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        #{channel_tags},
        {"allow":[{"domain":"#{event_domain}","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise #{event_domain} event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when #{event_domain} factory_reset
    foreach wrangler:channels(#{channel_tags}).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
>>
    }
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
  rule acceptNewApp {
    select when bazaar_apps new_app
      rid re#^([a-zA-Z][a-zA-Z0-9._-]+)$#
      home re#^([a-zA-Z][a-zA-Z0-9_]+)$#
      rsname re#([a-zA-Z][a-zA-Z0-9_]*)#
      setting(rid,home,rsname)
    pre {
      spec = {
        "rid": rid,
        "name": home,
        "rsname": rsname || home,
        "event_domain": rid.replace(re#[.-]#g,"_")
      }
    }
    fired {
      ent:apps{rid} := spec
    }
  }
  rule deleteApp {
    select when bazaar_apps app_not_wanted
      rid re#^(.+)$# setting(rid)
    fired {
      clear ent:apps{rid}
    }
  }
  rule redirectBack {
    select when bazaar_apps new_app
             or bazaar_apps app_not_wanted
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
