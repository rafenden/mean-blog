# Routes
class HomeRoutes extends Config
  constructor: ($routeProvider) ->
    $routeProvider
    .when '/',
      controller: 'HomeCtrl'
      templateUrl: '/views/home/home.html'

# Home controller
class HomeCtrl extends Controller
  constructor: ($scope, Page) ->
    Page.setDefaultTitle()

