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


# Page factory
class Page extends Factory
  @title: ''
  @titleSuffix: ''
  @breadcrumbs: []
  @tabs: []
  @$location: {}
  @bodyClasses: [] # This is not visible under

  constructor: ($location) ->
    return {
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
    }


# Page controller
class PageCtrl extends Controller
  constructor: ($scope, Page, $location, $window, angularLoad) ->
    $scope.$location = $location
    $scope.Page = Page

    $scope.$on '$routeChangeSuccess', (event, current, previous) ->
      Page.setTitle event.currentScope.pageTitle
      Page.setDefaults()

    # $window.scrollTo 0, 0


# Not found controller
class NotFoundCtrl extends Controller
  constructor: ($scope, Page) ->
    Page.setTitle '404 Not Found'
    Page.setBodyClass 'page-not-found'
