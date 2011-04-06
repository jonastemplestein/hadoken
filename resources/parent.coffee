# TODO buffer up listeners etc now
# and hook up to socket.io proper once iframe is there
hadoken or= {}

ifrm = document.createElement "IFRAME"
src = "http://#{hadoken.host}:#{hadoken.port}#{hadoken.path}"
ifrm.setAttribute "src", src
document.body.appendChild ifrm

console.log 'Hadoken parent loaded'