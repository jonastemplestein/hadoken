# GHETTO templating FTW
hadoken = window.parent[_hadoken_conf.globalVariable] or= {}

if _hadoken_conf.enableSocket
  socket = hadoken.socket = new io.Socket document.location.hostname, \ 
      _hadoken_conf.socketClientOptions

if _hadoken_conf.enableAjax
  hadoken.ajax = window.reqwest

if typeof hadoken.init is 'function'
  hadoken.initialized = true
  hadoken.init()
