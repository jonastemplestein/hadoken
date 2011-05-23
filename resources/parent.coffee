
# TODO buffer up listeners etc now
# and hook up to socket.io proper once iframe is there

hadoken = window[_hadoken_conf.globalVariable] or= {}

if typeof window.console is 'undefined'
  window.console =
    log: (->)
    error: (->)
    dir: (->)

ifrm = document.createElement "IFRAME"
ifrm.style.display = "none"
src = "IFRAME_URL"
ifrm.setAttribute "src", src
document.body.appendChild ifrm

console.log "Hadoken: #{_hadoken_conf.globalVariable} parent loaded"
