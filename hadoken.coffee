###

  # Hadoken
  
  ## TODO
    - Enable true cross-domain push/api access using `easyXDM`. Make it
      optional via enableCrossdomain option. In cross-domain we also need
      to proxy the socket.io api on the parent hadoken object (instead of 
      using the child object as-is)
    - Get rid of connect dependency
    - Allow `globalVariable = 'namespace.var';`
    - Improve parent script to allow same global variable to be used for
      multiple backends. If FB for example had two hosts, graph.facebook.com
      and realtime.facebook.com, it would be nice if both could be accessed
      through a global FB object.
    - Allow embedding wrapper-libraries directly into `parent.js`
    - Allow changing options while the server is running for robustness.
      We could e.g. re-render the iframe and parent js everytime a `setOpts`
      method is called.
    - Figure out whether there is any reason not to set document.domain
      to the second level domain from the request's host header
    - consider automatically setting document.domain in parent.js. What
      will that break?
    
    
###

http = require 'http'
fs = require 'fs'
coffee = require 'coffee-script'

# TODO get rid of connect dependency. i was just too lazy ^^
connect = require 'connect'
path = require 'path'

class Hadoken 

  # ## Configuration
  @defaults =
    
    # (optional) Pass in an instance of connect.HTTP(S)Server to hook
    # hadoken up to. If you omit this, a server will be created for you,
    # but you must call `.listen()` on it yourself.
    #
    # WARNING: if you want to use socket.io, the server needs to be the one
    # that you later call `.listen()` on. You can't nest it in yet another
    # server.
    server: null

    # All other paths are relative to `rootEndpoint`.
    rootEndpoint: "hadoken/"

    # Serve iframe on `http://host:port/hadoken/` by default
    iframeFilename: "" 
    
    # Used as domain policy (`document.domain = x`) if set. Set this to your
    # base domain if you want to use your api/push server from a different
    # subdomain.
    baseDomain: undefined
    
    # Global variable that is exposed to parent window. Defaults to `hadoken`.
    # Set this if you have multiple hadokens on the same page (e.g. one for
    # push.yourdomain.com and one for api.yourdomain.com) or if you want to
    # expose your API to third parties (Facebook might set this to `FB`)
    globalVariable: 'hadoken'

    # Name of the script that sites using your API need to include.
    # For all default values, you can load hadoken from
    # `http://host:port/hadoken/parent.js` which will provide a global
    # variable `hadoken` that you can use to make requests.
    parentJsFile: 'parent.js'

    # Set `enableAjax` to true to enable the `request()` method
    # on the hadoken object (e.g. `hadoken.request()`).
    enableAjax: true
    
    # Set to true to serve socket.io according to socketOptions.
    # See `socket.io-node` docs for socketOptions.
    # NOTE: if you set socketOptions.resource, you must set it on
    #       socketClientOptions as well
    enableSocket: false
    socketOptions: {}
    # Options for the socket.io client
    socketClientOptions: {}
    
    
  # ## Public API

  constructor: (options={}) ->

    @_setOpts options
    @_server = @options.server or connect.createServer()

    # Add socket.io to server if desired. Get a handle on the `Listener`
    # instance using `.getSocket()` to attach event handlers etc.
    if @options.enableSocket
      @options.socketClientOptions.resource or= @_getSocketIOEndpoint()
      @options.socketOptions.resource or= @_getSocketIOEndpoint()
      @_socket = require('socket.io').listen @_server, @options.socketOptions

    # Serve iframe and parent javsacript file
    @_server.use connect.router (app) =>
      app.get @_path(@options.parentJsFile), @_serveParentJs
      app.get @_path(@options.iframeFilename), @_serveIframe


  # Returns your `io.Listener` instance.
  getSocket: -> @_socket

  # You'll need this to get at the server that was created for you
  # if you don't pass in a server
  getServer: -> @_server
  

  # ## Internals
  # generate parent javascript from template in `resources/parent.coffee`
  _makeParentJs: ->
    parent_coffee = fs.readFileSync @_resource('parent.coffee'), 'utf8'
    js = coffee.compile parent_coffee
    js = @_getClientConfigSnippet() + js
    return @_wrapJs js

  # Generate iframe html from template in `resources/receiver.html`
  _makeIframeHtml: ->
    template = fs.readFileSync @_resource('receiver.html'), 'utf8'

    # 1. configure client
    script = @_getClientConfigSnippet()

    # 2. load dependencies
    if @options.enableSocket
      script += fs.readFileSync @_resource('socket.io.js'), 'utf8'
    if @options.enableAjax
      script += fs.readFileSync @_resource('reqwest.js'), 'utf8'

    # 3. bootstrap!
    receiver_coffee = fs.readFileSync @_resource('child.coffee'), 'utf8'
    script += coffee.compile receiver_coffee
    script = @_wrapJs script
    script = @_getDomainPolicySnippet() + script
    return template.replace '{SCRIPT}', script


  # Returns a sanitized path relative to root endpoint.
  _path: -> path.join '/', @options.endpoint, arguments...

  # Sets and merges options
  _setOpts: (opts) ->
    @options = opts
    for key, val of @constructor.defaults
      @options[key] = val if typeof @options[key] is 'undefined'

  # Some functions for the http responses. This is broken up like this
  # to make it easier to get rid of connect and allow in-flight option changing
  # in the future.
  _respond: (res, content_type, content, length) =>
    res.writeHead 200,
      'Content-Type': content_type
      'Content-Length': length
    res.end content
  _serveIframe: (req, res, next) =>
    [html, length] = @_getCachedIframe()
    @_respond res, 'text/html; charset=UTF-8', html, length
  _serveParentJs: (req, res, next) =>
    [js, length] = @_getCachedParentJs()
    # HACK: use req.headers.host field to figure out where
    # the parent should request the iframe from. This way the
    # developer doesn't have to pass host/port to hadoken.
    # Downside is reduced performance and general hackyness
    host = req?.headers?.host or ''
    iframe_url = "http://#{host}#{@_path @options.iframeFilename}"
    placeholder_length = 'IFRAME_URL'.length
    iframe_length = Buffer.byteLength iframe_url
    js = js.replace 'IFRAME_URL', iframe_url
    length = length - placeholder_length + iframe_length
    @_respond res, 'application/javascript; charset=UTF-8', js, length

  _getCachedIframe: ->
    if not @_cached_iframe
      @_cached_iframe = @_makeIframeHtml()
      @_cached_iframe_length = Buffer.byteLength @_cached_iframe
    return [@_cached_iframe, @_cached_iframe_length]

  _getCachedParentJs: ->
    if not @_cached_js
      @_cached_js = @_makeParentJs()
      @_cached_js_length = Buffer.byteLength @_cached_js
    return [@_cached_js, @_cached_js_length]
  _wrapJs: (js) -> "(function(){#{js}})();"
  _getDomainPolicySnippet: ->
    if @options.baseDomain
      return "document.domain = '#{@options.baseDomain}';\n"
    else return ''

  _getClientConfigSnippet: ->
    child_opts =
      globalVariable: @options.globalVariable
      enableSocket: @options.enableSocket
      enableAjax: @options.enableAjax
      socketClientOptions: @options.socketClientOptions
      
    return "var _hadoken_conf = #{JSON.stringify(child_opts)};\n";

  _getSocketIOEndpoint: ->
    resource = @_path 'socket.io'
    # hack to remove leading slash
    if resource[0] is '/'
      resource = resource.substr 1
    return resource
    
  # Helper function to find resources for this module.
  _resource: (name) -> "#{__dirname}/resources/#{name}"

module.exports =
  Hadoken: Hadoken
  listen: -> new Hadoken arguments...
