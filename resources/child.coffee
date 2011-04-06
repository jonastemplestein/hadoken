console.log 'Hadoken child loaded'

# TODO
# - hadoken should be a proxy for socket.io.
# - notify parent window that the connection is established
window.parent.hadoken or= {}
hadoken = window.parent.hadoken
socket = hadoken.socket = new io.Socket hadoken.host,
  port: hadoken.port
socket.connect()

socket.on 'connect', -> hadoken.init() if hadoken.init
