# App initialisation
class Application extends App
  constructor: ->
    return [
      'ngRoute'
      'ui.ace'
      'angularLoad'
      'ngSocial'
      'ngStorage'
      'angular-loading-bar'
      'angularUtils.directives.dirDisqus'
    ]


# Routes
class GlobalRoutes extends Config
  constructor: ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode true

    $routeProvider
    .otherwise
      controller: 'NotFoundCtrl'
      templateUrl: '/views/404.html'


# Runtime set up
class Runtime extends Run
  constructor: ($rootScope) ->
    # Global resolve
    $rootScope.$on '$routeChangeStart', (event, current, previous) ->


# Site factory
class Site extends Factory
  @title: ''
  @titleSuffix: ''
  @breadcrumbs: []
  @tabs: []
  @$location: {}
  @bodyClasses: [] # This is not visible under

  constructor: ($location) ->
    return {
      isFrontPage: ->
        @getCurrentURL() is '/'

      setDefaultTitle: ->
        @titleSuffix = @title = Config.siteName

      getTitle: (showSuffix = false) ->
        @title

      getTitleWithSuffix: ->
        if @titleSuffix and @title isnt @titleSuffix
          "#{@title} | #{@titleSuffix}"
        else
          @title

      setTitle: (t) ->
        if not @titleSuffix
          @setDefaultTitle()
        @title = t

      replaceTitleTokens: (replacements) ->
        # TODO: check if is array
        # TODO: get tokens from title and replace them with "replacements" variable
        # @title.replace()

      setBreadcrumbs: (b) ->
        @breadcrumbs = b

      getBreadcrumbs: ->
        @breadcrumbs

      setTabs: (t) ->
        @tabs = t

      getTabs: ->
        @tabs

      setDefaultBodyClass: ->
        # Construct body CSS class based on actual URL.
        @bodyClasses = []
        @bodyClasses.push 'page-' + $location.path().substr(1).replace(/\//g, '-')

      setBodyClass: (cssClass) ->
        @bodyClasses = cssClass

      getBodyClass: ->
        @bodyClasses

      setDefaults: ->
        # @setDefaultTitle()
        @setBreadcrumbs(null)
        @setTabs []
        @setDefaultBodyClass()

      getCurrentURL: (absolute = false) ->
        if (absolute)
          $location.absUrl()
        else
          $location.url()

      getBaseUrl: ->
        $location.protocol() + '://' + $location.host() + ':' + $location.port()

      initAceEditor: (editor) ->
        editor.setOptions
          minLines: 5
          maxLines: 'Infinity'
          tabSize: 2
          autoScrollEditorIntoView: true
          wrap: true
          showLineNumbers: false
          showGutter: false
          showPrintMargin: false
    }


# Site controller
class SiteCtrl extends Controller
  constructor: ($scope, Site, $location, $window, angularLoad) ->
    $scope.$location = $location
    $scope.Site = Site

    $scope.$on '$routeChangeSuccess', (event, current, previous) ->
      Site.setTitle event.currentScope.pageTitle
      Site.setDefaults()

    # $window.scrollTo 0, 0


# Not found controller
class NotFoundCtrl extends Controller
  constructor: ($scope, Site) ->
    Site.setTitle '404 Not Found'
    Site.setBodyClass ['page-not-found']
