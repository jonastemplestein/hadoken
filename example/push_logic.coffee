# i can put all my push crap here
# if i want to, i can host this part of the app on a different machine!

module.exports =
  hookup: (socketio_server) ->
    socketio_server.on 'connection', (client) ->
      i = 0
      interval = setInterval ->
        client.send i++
      , 1000
      client.on 'disconnect', -> clearInterval interval
