# Routes
class BlogRoutes extends Config
  constructor: ($routeProvider) ->
    $routeProvider
    .when '/blog',
      controller: 'BlogListCtrl'
      templateUrl: '/views/blog/postsList.html'
    .when '/blog/add',
      controller: 'BlogAddCtrl'
      templateUrl: '/views/blog/postForm.html'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/blog/:slug',
      controller: 'BlogViewCtrl'
      templateUrl: '/views/blog/postView.html'
    .when '/blog/:slug/edit',
      controller: 'BlogEditCtrl'
      templateUrl: '/views/blog/postForm.html'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/blog/:slug/delete',
      controller: 'BlogDeleteCtrl'
      templateUrl: '/views/blog/postDelete.html'


# Blog controller
class BlogHelper extends Factory
  constructor: ->
    return BlogHelper

  @getTabs: (post) ->
    [
      {title: 'View', url: "/blog/#{post.slug}"}
      {title: 'Edit', url: "/blog/#{post.slug}/edit"}
      {title: 'Delete', url: "/blog/#{post.slug}/delete"}
    ]
  @getAceConfig: ->


# List of blog posts
class BlogListCtrl extends Controller
  constructor: ($scope, BlogService, Site) ->
    Site.setTitle 'Blog'
    Site.setBreadcrumbs [
      {title: 'Blog'}
    ]

    BlogService.getList().then (results) ->
      $scope.posts = results.posts


# List of recent blog posts
class BlogRecentListCtrl extends Controller
  constructor: ($scope, BlogService, Site) ->
    BlogService.getList(10).then (results) ->
      $scope.posts = results.posts


# Create blog post
class BlogAddCtrl extends Controller
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Site, $location, $filter) ->
    Site.setTitle 'Add blog post'
    Site.setBreadcrumbs [
      {title: 'Blog', url: '/blog'}
      {title: Site.getTitle()}
    ]
    Site.setBodyClass ['blog-post-add', 'blog-post-form']

    $scope.customUrl = false

    $scope.updateSlug = ->
      if !$scope.customUrl
        friendlySlug = $filter('friendlyUrl')($scope.post.title)
        $scope.post.slug = friendlySlug

    $scope.aceLoaded = Site.initAceEditor

    $scope.disableAutoUrl = ->
      $scope.customUrl = true

    $scope.submitPost = ->
      BlogService.createPost($scope.post)
      .success (data, status, headers, config) ->
        $location.path '/blog'
      .error (data, status, headers, config) ->
        alert angular.toJson data


# View blog post
class BlogViewCtrl extends Controller
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Site, $location, $route) ->
    Site.setBodyClass ['blog-post-view']

    $scope.post = null
    $scope.showComments = false
    $scope.disqus_shortname = Config.disqus_shortname

    BlogService.getPost($routeParams.slug).then (results) ->
      # TODO: execute PageNotFound() and check if any redirects exists
      # TODO: check if redirections works with PhantomJS
      if !results then $location.path "/not-found?from=blog/#{$routeParams.slug}"

      Site.setTitle results.title
      Site.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title}
      ]
      console.log Site
      Site.setTabs BlogHelper.getTabs results
      $scope.post = results
      $scope.showComments = true


# Edit blog post
class BlogEditCtrl extends Controller
  constructor: (BlogService, BlogHelper, Site, $scope, $routeParams, $location) ->
    BlogService.getPost($routeParams.slug).then (results) ->
      if !results then $location.path '/not-found'

      Site.setTitle "Edit #{results.title}"
      Site.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title, url: "/blog/#{results.slug}"}
        {title: 'Edit'}
      ]
      Site.setTabs BlogHelper.getTabs results
      Site.setBodyClass ['blog-post-edit', 'blog-post-form']

      $scope.post = results

    $scope.updateSlug = $scope.disableAutoUrl = ->
    $scope.aceLoaded = Site.initAceEditor

    $scope.submitPost = ->
      tagsArray = []

      if $scope.post.tags?.split?
        tagsArray = $scope.post.tags.split(',')
        for tag, i in tagsArray
          tagsArray[i] = tagsArray[i].trim()

      BlogService.savePost($scope.post)
      .success (data, status, headers, config) ->
        $location.path "/blog/#{$scope.post.slug}"
      .error (data, status, headers, config) ->
        alert angular.toJson data


# Delete blog post
class BlogDeleteCtrl extends Controller
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Site, $location) ->
    Site.setBodyClass ['blog-post-delete']
    BlogService.getPost($routeParams.slug).then (results) ->
      Site.setTitle "Delete #{results.title}"
      Site.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title, url: "/blog/#{results.slug}"}
        {title: 'Delete'}
      ]
      Site.setTabs BlogHelper.getTabs results

      $scope.post = results

    $scope.deletePost = ->
      BlogService.deletePost($scope.post._id).then (results) ->
        $location.path '/blog'


# Blog service
class BlogService extends Service
  endpointUrl = "#{Config.endpointUrl}/blog"

  constructor: (@$http, @$location, @Site) ->

  # Get list of blog posts
  getList: (limit = 0) ->
    @$http.get("#{endpointUrl}?limit=#{limit}")
    .then (results) ->
      results.data

  # Get single post
  getPost: (slug) ->
    baseUrl = @Site.getBaseUrl() + '/blog/'
    @$http.get("#{endpointUrl}?slug=#{slug}")
    .then (results) ->
      if results.data.posts[0]?
        results.data.posts[0].url = ->
          return baseUrl + results.data.posts[0].slug
      results.data.posts[0]

  # Save/edit post
  savePost: (post) ->
    @$http.put("#{endpointUrl}/#{post._id}", post)
    .error (results, status) ->
      {results, status}

  # Create post
  createPost: (post) ->
    @$http.post endpointUrl, post

  # Delete post
  deletePost: (id) ->
    @$http.delete("#{endpointUrl}/#{id}")
    .error (results, status) ->
      {results, status}
