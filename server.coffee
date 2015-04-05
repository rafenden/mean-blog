# Include node modules
express = require 'express'
{join} = require 'path'
assets = require './lib/assets'
http = require 'http'
https = require 'https'
fs = require 'fs'

# Initialise app
app = express()

# Get configuration
config = require 'config'

# Configuration
app.set 'views', join(__dirname, 'views')
app.set 'view engine', 'jade'
app.set 'view options',
  pretty: true

app.locals.Config = config.get 'clientside'
app.locals.pretty = true

# Detect if connection is secure.
app.use (req, res, next) ->
  if req.protocol is 'http'
    app.locals.Config.endpointUrl = config.get('http').endpointUrl
  else
    app.locals.Config.endpointUrl = config.get('https').endpointUrl
  next()

# Compile on-the-fly assets and serve them to browser
app.get '/app/:script.js', assets.serveScripts
app.get '/styles/:style.css', assets.serveStyles

# Serve sattic files
app.use express.static __dirname + '/public'
app.use('/bower_components', express.static(__dirname + '/bower_components'))

# Prerender pages for SEO purposes
app.use require('prerender-node').set('prerenderServiceUrl', config.get 'prerenderUrl')

# Serve template files
app.use assets.servePartials

## Catch 404 and forwarding to error handler
app.use (req, res, next) ->
  res.render 'blank',

# Development error handler (print stacktrace)
if app.settings.env is 'development'
  app.use (err, req, res, next) ->
    res.status err.status ? 500
    res.render 'error',
      title: err.title ? 'Error'
      message: err.message
      error: err

# Production error handler (no stacktraces leaked to user)
else if app.settings.env isnt 'development'
  app.use (err, req, res, next) ->
    res.status err.status ? 500
    res.render 'error',
      title: err.title ? 'Error'
      message: err.message
      error: {}

# Register exit handlers
exitApp = ->
  console.log 'Shutting down...'
  process.exit 0

process.on 'SIGINT', exitApp
process.on 'SIGTERM', exitApp

privateKey  = fs.readFileSync config.get('https').privateKey, 'utf8'
certificate = fs.readFileSync config.get('https').certificate, 'utf8'
credentials = key: privateKey, cert: certificate

httpServer = http.createServer app
httpsServer = https.createServer credentials, app

# Start server
httpServer.listen config.get('http').port, ->
  console.log 'Express server listening on port %d in %s mode', config.get('http').port, app.settings.env

httpsServer.listen config.get('https').port, ->
  console.log 'Express server listening on port %d in %s mode', config.get('https').port, app.settings.env
