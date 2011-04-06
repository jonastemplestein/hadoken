# in development:
#  - piggyback push server on this server
#
# in production
#  - connect to push server on different domain

require.paths.unshift '../node_modules'

connect = require 'connect'
fs = require 'fs'
hadoken = require '../index'
push_logic = require './push_logic'

process.env.NODE_ENV or= 'development'
if process.argv[2] then process.env.NODE_ENV = process.argv[2]

NODE_ENV = process.env.NODE_ENV

if NODE_ENV not in ['development', 'production']
  console.error 'Come on'
  process.exit()

console.log "Starting server in #{NODE_ENV} mode ..."

DEV_MODE = NODE_ENV is 'development'

server = connect.createServer()

# production settings
template_vars =
  hadoken_host: 'push.localhost.com'
  hadoken_port: '8080'
  hadoken_path: '/'

if DEV_MODE
  # hadoken hooks up socket.io and hosts
  # all required static files for this spiel
  socketio_server = hadoken.listen
    server: server
    path: '/hadoken/'

  # in dev mode we want to also run the push logic
  push_logic.hookup socketio_server
  
  template_vars =
    hadoken_host: 'localhost.com'
    hadoken_port: '8080'
    hadoken_path: '/hadoken/'

server.use (req, res, next) ->

  fs.readFile './templates/index.html', 'utf8', (err, index_html) ->
    return next err if err

    # GHETTO TEMPLATING FTW!
    for key, val of template_vars
      regexp = new RegExp "{#{key}}", "g"
      index_html = index_html.replace regexp, val

    res.writeHead 200,
      'Content-Length': Buffer.byteLength index_html
      'Content-Type': 'text/html; charset=UTF-8'
    res.end index_html

server.listen 8080, '127.0.0.1'