# Routes
class PageRoutes extends Config
  constructor: ($routeProvider) ->
    $routeProvider
    .when '/page',
      controller: 'PageListCtrl'
      templateUrl: '/views/page/pagesList.html'
    .when '/page/add',
      controller: 'PageAddCtrl'
      templateUrl: '/views/page/pageForm.html'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/page/:slug',
      controller: 'PageViewCtrl'
      templateUrl: '/views/page/pageView.html'
    .when '/page/:slug/edit',
      controller: 'PageEditCtrl'
      templateUrl: '/views/page/pageForm.html'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/page/:slug/delete',
      controller: 'PageDeleteCtrl'
      templateUrl: '/views/page/pageDelete.html'


# List of pages
class PageListCtrl extends Controller
  constructor: ($scope, PageService, Site) ->
    Site.setTitle 'Pages'
    Site.setBreadcrumbs [
      {title: 'Pages'}
    ]

    PageService.getList().then (results) ->
      $scope.pages = results.pages


# Create page page
class PageAddCtrl extends Controller
  constructor: ($scope, $routeParams, PageService, Site, $location, $filter) ->
    Site.setTitle 'Add page'
    Site.setBreadcrumbs [
      {title: Site.getTitle()}
    ]
    Site.setBodyClass ['page-add', 'page-form']

    $scope.customUrl = false
    $scope.cancelUrl = '/'

    $scope.updateSlug = ->
      if !$scope.customUrl
        friendlySlug = $filter('friendlyUrl')($scope.page.title)
        $scope.page.slug = friendlySlug

    $scope.aceLoaded = Site.initAceEditor

    $scope.disableAutoUrl = ->
      $scope.customUrl = true

    $scope.submitPage = ->
      PageService.createPage($scope.page)
      .success (data, status, headers, config) ->
        $location.path "/page/#{$scope.page.slug}"
      .error (data, status, headers, config) ->
        alert angular.toJson data


# View page page
class PageViewCtrl extends Controller
  constructor: ($scope, $routeParams, PageService, PageHelper, Site, $location, $route) ->
    Site.setBodyClass ['page-view']

    $scope.page = null
    $scope.showComments = false
    $scope.disqus_shortname = Config.disqus_shortname

    PageService.getPage($routeParams.slug).then (results) ->
      # TODO: execute PageNotFound() and check if any redirects exists
      # TODO: check if redirections works with PhantomJS
      if !results then $location.path "/not-found?from=page/#{$routeParams.slug}"

      Site.setTitle results.title
      Site.setBreadcrumbs [
        {title: results.title}
      ]
      Site.setTabs PageHelper.getTabs results
      $scope.page = results
      $scope.showComments = true


# Edit page page
class PageEditCtrl extends Controller
  constructor: (PageService, PageHelper, Site, $scope, $routeParams, $location) ->
    PageService.getPage($routeParams.slug).then (results) ->
      if !results then $location.path '/not-found'

      Site.setTitle "Edit #{results.title}"
      Site.setBreadcrumbs [
        {title: results.title, url: "/page/#{results.slug}"}
        {title: 'Edit'}
      ]
      Site.setTabs PageHelper.getTabs results
      Site.setBodyClass ['page-edit', 'page-form']

      $scope.cancelUrl = "/page/#{results.slug}"
      $scope.page = results

    $scope.updateSlug = $scope.disableAutoUrl = ->
    $scope.aceLoaded = Site.initAceEditor

    $scope.submitPage = ->
      tagsArray = []

      if $scope.page.tags?.split?
        tagsArray = $scope.page.tags.split(',')
        for tag, i in tagsArray
          tagsArray[i] = tagsArray[i].trim()

      PageService.savePage($scope.page)
      .success (data, status, headers, config) ->
        $location.path "/page/#{$scope.page.slug}"
      .error (data, status, headers, config) ->
        alert angular.toJson data


# Delete page page
class PageDeleteCtrl extends Controller
  constructor: ($scope, $routeParams, PageService, PageHelper, Site, $location) ->
    Site.setBodyClass ['page-delete']
    PageService.getPage($routeParams.slug).then (results) ->
      Site.setTitle "Delete #{results.title}"
      Site.setBreadcrumbs [
        {title: results.title, url: "/page/#{results.slug}"}
        {title: 'Delete'}
      ]
      Site.setTabs PageHelper.getTabs results

      $scope.page = results

    $scope.deletePage = ->
      PageService.deletePage($scope.page._id).then (results) ->
        $location.path '/'


# Page helper
class PageHelper extends Factory
  constructor: ->
    return PageHelper

  @getTabs: (page) ->
    [
      {title: 'View', url: "/page/#{page.slug}"}
      {title: 'Edit', url: "/page/#{page.slug}/edit"}
      {title: 'Delete', url: "/page/#{page.slug}/delete"}
    ]


# Page service
class PageService extends Service
  endpointUrl = "#{Config.endpointUrl}/page"

  constructor: (@$http, @$location, @Site) ->

  # Get list of page pages
  getList: (limit = 0) ->
    @$http.get("#{endpointUrl}?limit=#{limit}")
    .then (results) ->
      results.data

  # Get single page
  getPage: (slug) ->
    baseUrl = @Site.getBaseUrl() + '/page/'
    @$http.get("#{endpointUrl}?slug=#{slug}")
    .then (results) ->
      if results.data.pages[0]?
        results.data.pages[0].url = ->
          return baseUrl + results.data.pages[0].slug
      results.data.pages[0]

  # Save/edit page
  savePage: (page) ->
    @$http.put("#{endpointUrl}/#{page._id}", page)
    .error (results, status) ->
      {results, status}

  # Create page
  createPage: (page) ->
    @$http.post endpointUrl, page

  # Delete page
  deletePage: (id) ->
    @$http.delete("#{endpointUrl}/#{id}")
    .error (results, status) ->
      {results, status}
