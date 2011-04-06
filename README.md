This will all make more sense once i finish all the todo items at the bottom.

# What is this?

***On the client*** Hadoken exposes a socket.io client (and soon a simple AJAX api) that can connect to a subdomain that runs a hadoken server. it has full push and ajax support (no jsonp or some such crap)

***On the server*** You can run a socket.io push server independently from the rest of your app on a different subdomain. i consider this a best practice and it allows you to retrofit existing apps on your domain with cool new push features.

this is pretty much the same as twitter's phoenix. twitter uses it for ajax requests from twitter.com to api.twitter.com. in this first rough draft i use it just for socket.io connections, but ajax is next in line.

# How to run the example in dev and production mode

I'm drunk and tired so I'll make it real quick. The example assumes you have two hosts in `/etc/hosts` defined like this

    127.0.0.1	localhost.com
    127.0.0.2	push.localhost.com

You can add the `127.0.0.2` ip to your loopback interface like this (on mac, probably similar-ish on linux) `sudo ifconfig lo0 alias 127.0.0.2` (the alias will disappear on reboot). Don't forget to `sudo dscacheutil -flushcache` to re-read the hosts file.

Examples require 'coffee-script', 'connect' and 'socket.io' to be installed in npm. Install them into the hadoken directory, I'll make a package.json later.

The example is in the example directory, cd there. To test out development mode (only one server running that serves both your app or whatever and the socket.io server), run `coffee server.coffee`. Point your browser to `http://localhost.com:8080` and watch the magic in the console.

To test out production mode, you'll have to start two servers. From the example directory run `coffee server.coffee production`. This will launch the webapp but it won't hook up socket.io. background the task and run `coffee push_server.coffee` in the same directory. this will start a socket.io server that runs on push.localhost.com:8080. Point your browser to `http://localhost.com:8080` again and you'll see push still working. booya.


# Why? (aka FAQ)

Because I'm an eccentric idealist and I want as little crap as possible to interfere with or share a process/machine/datacenter with my webapp's push server. Maybe the push server and the rest of my app have different scaling requirements and I want to have to put them all on the same machines and behind the same load balancers. In fact, I may want to use a load balancer that doesn't speak websockets for most of my app. I also like to have a clean separation of concerns.

More pragmatically, suppose I have a bunch of existing web properties on all kinds of subdomains of mydomain.com. Now I add this shiny new service at api.mydomain.com. What is the easiest way of making that new service available to all my properties? Hadoken! Boom.

Just to be clear: for vanilla websockets this is not even necessary since they can in fact connect to other sudomains. The problem is with the fallback methods like XHR that don't work on subdomains.

# TODO
 
 * Make a proper example that's easier to run
 
 * Figure out npm v1.0 stuff
 
 * Improve hadoken API, the example app still feels a little funky

 * Make hadoken server write configuration vars into parent frame

 * Remove dependency on connect, I was just lazy

 * Buffer all socket.io-related function calls in window.hadoken in the parent until hadoken becomes functional

 * don't copy-paste socket.io client js (and find out why minified version failed)

 * implement a less arbitrary loading and configuration pattern
 
 * Expose AJAX abstraction and make the whole thing independent from socket.io.