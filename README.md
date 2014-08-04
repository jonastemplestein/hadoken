MAIN TODO: improve this readme. For the moment, you're better off reading the sourcecode of hadoken.coffee

WARNING: there may still be some custom-to-us parts in the code. Feel free to tinker.

# What is this?

Hadoken makes your node.js REST and/or push (via socket.io) API available on subdomains and as soon as I get to it on other domains.

Just create your server like you normally would, then call `hadoken.listen` on it with the appropriate options and suddenly you're serving an xd receiver iframe and a bunch of javascript from your server that just works.

Currently there's a dependency on connect servers because I was lazy, so keep that in mind.

Here's a really quick example (pardon my coffeescript):

***Server on api.example.com***

    server = connect.createServer '/sayhi', (req, res, next) ->
      res.end 'hi'
    
    hadoken.listen
      baseDomain: 'example.com'
      server: server
    
    server.listen 80

***Client on cdn.example.com***
    
    <script src="http://api.example.com/hadoken" />
    <script>
      hadoken.ajax({
        url: 'http://api.example.com/sayhi',
        success: function(){
          alert('yea!')
        }
      });
      
      // if you set enableSocket to true when calling hadoken.listen
      // you can also get a handle on a socketio connection using
      // hadoken.socket
    </script>


The client uses a patched version of the reqwest library but that may change soon

# Why?

I initially wrote this to pull out a push server from our API server to separate concerns better. Then it occurred to me that this could be used to public API-ify random webservices and that's awesome. Like I said though, cross-domain is not implemented yet.

At campfire labs using hadoken allows us to serve all functionality (push, api, static file serving) from one process in development and from three different processes in production. It's pretty sweer