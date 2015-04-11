# Routes
class HomeRoutes extends Config
  constructor: ($routeProvider) ->
    $routeProvider
    .when '/',
      controller: 'HomeCtrl'
      templateUrl: '/views/home/home.html'

# Home controller
class HomeCtrl extends Controller
  constructor: ($scope, Site) ->
    Site.setDefaultTitle()
    $scope.$parent.loaded = true

