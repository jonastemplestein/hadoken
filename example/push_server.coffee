# stand alone push server for production
hadoken = require '../index'
socketio_server = hadoken.listen
  port: 8080
  host: '127.0.0.2'

push_logic = require './push_logic'
push_logic.hookup socketio_server
