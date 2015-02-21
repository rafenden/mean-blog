basedir = process.cwd()
fs = require 'fs'
coffee = require 'coffee-script'
ngClassify = require 'ng-classify'
stylus = require 'stylus'
nib = require 'nib'


# Compile on-the-fly *.coffee files to *.js
exports.serveScripts = (req, res, next) ->
  file = "#{basedir}/app/#{req.params.script}.coffee"
  # TODO: Save file as static JS so it don't have to be compiled it every time
  if fs.existsSync file
    res.header 'Content-Type', 'application/x-javascript'
    coffeeFile = fs.readFileSync file, 'ascii'

    # See: https://github.com/CaryLandholt/ng-classify#options
    ngClassifyOptions =
      controller: format: '*', suffix: ''
      directive: format: '*', suffix: ''
      factory: format: '*', suffix: ''
      provider: format: '*', suffix: ''
      service: format: '*', suffix: ''

    res.send coffee.compile ngClassify coffeeFile, ngClassifyOptions
  else next()


# Compile on-the-fly *.styl files to *.css
exports.serveStyles = (req, res, next) ->
  file = "#{basedir}/styles/#{req.params.style}.styl"
  # TODO: Save file as static CSS so it don't have to be compiled it every time
  if fs.existsSync file
    res.header 'Content-Type', 'text/css'
    stylusFile = fs.readFileSync file, 'ascii'

    # See: https://www.npmjs.org/package/stylus-renderer#render-stylesheets-options-cb-
    stylusOptions =
      compress: 'true'

    res.send stylus(stylusFile, stylusOptions).use(nib()).render()
  else next()

# Compile on-the-fly *.jade files to *.html
exports.servePartials = (req, res, next) ->
  requestedFile = req._parsedUrl.pathname
  if requestedFile.indexOf('/views/') isnt 0 then return next()
  templateFilePath = requestedFile.replace '.html', '.jade'
  if templateFilePath.charAt 0 is '/' then templateFilePath = templateFilePath.substr 1
  renderPath = requestedFile.replace('.html', '').replace '/views/', ''
  
  # TODO: Save file as static HTML so it don't have to be compiled it every time
  if fs.existsSync templateFilePath then res.render renderPath
  else next()

exports.getScripts = ->
  return fs.readdir "#{basedir}/app", (err, files) ->
    if err then throw err
    return files
