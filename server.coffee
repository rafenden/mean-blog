# Include node modules
express = require 'express'
{join} = require 'path'
assets = require './lib/assets'

# Initialise app
app = express()

# Get configuration
config = require 'config'

# Configuration
app.set 'views', join(__dirname, 'views')
app.set 'view engine', 'jade'
app.set 'view options',
  pretty: true
app.set 'port', process.env.PORT ? config.get 'port'

app.locals.Config = config.get 'clientside'
app.locals.pretty = true

# Compile on-the-fly assets and serve them to browser
app.get '/app/:script.js', assets.serveScripts
app.get '/styles/:style.css', assets.serveStyles

app.use('/favicons', express.static(__dirname + '/favicons'))
app.use('/bower_components', express.static(__dirname + '/bower_components'))

# Prerender pages to for SEO purposes
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

# Start server
app.listen app.settings.port, ->
  console.log 'Express server listening on port %d in %s mode', app.settings.port, app.settings.env
