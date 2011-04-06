# desired api:
# > hadoken = require('hadoken');
# > hadoken.listen(options)
# where options contains either an http server
# or host/port combination.

http = require 'http'
io = require 'socket.io'
fs = require 'fs'
coffee = require 'coffee-script'
connect = require 'connect'
path = require 'path'

default_opts = 
  server: null # if server is set, host and port areignored
  port: 8080
  host: '127.0.0.2'
  path: '/'

resource = (name) -> "#{__dirname}/resources/#{name}"

# returns HTML of the iframe
iframeContent = ->
  template = fs.readFileSync resource('receiver.html'), 'utf8'
  script = fs.readFileSync resource('socket.io.js'), 'utf8'
  receiver_coffee = fs.readFileSync resource('child.coffee'), 'utf8'
  script += coffee.compile receiver_coffee
  # ghetto templating ftw!
  return template.replace '{SCRIPT}', script

parentJs = ->
  parent_coffee = fs.readFileSync resource('parent.coffee'), 'utf8'
  return coffee.compile parent_coffee
  
listen = (opts) ->
  
  for key, val of default_opts
    opts[key] or= default_opts[key]
  
  server = opts.server
  stand_alone = false

  if not server
    stand_alone = true
    server = connect.createServer()

  socket = io.listen server

  parent_js = parentJs()
  parent_js_length = Buffer.byteLength parent_js
  server.use path.normalize(opts.path+'/parent.js'), (req, res, next) ->
    res.writeHead 200,
      'Content-Type': 'application/javascript; charset=UTF-8'
      'Content-Length': parent_js_length
    res.end parent_js
  
  iframe_html = iframeContent()
  iframe_html_length = Buffer.byteLength iframe_html
  server.use opts.path, (req, res, next) ->
    res.writeHead 200,
      'Content-Type': 'text/html; charset=UTF-8'
      'Content-Length': iframe_html_length
    res.end iframe_html
  
  if stand_alone
    console.log 'listening on ', opts.port, opts.host
    server.listen opts.port, opts.host

  # expose socket.io for now
  return socket
  
module.exports =
  listen: listen
