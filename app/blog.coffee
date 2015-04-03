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
      permission: 'add blog post'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/blog/:slug',
      controller: 'BlogViewCtrl'
      templateUrl: '/views/blog/postView.html'
      title: ':postTitle'
      actionTitle: 'View'
    .when '/blog/:slug/edit',
      controller: 'BlogEditCtrl'
      templateUrl: '/views/blog/postForm.html'
      permission: 'edit blog post'
      tabTitle: 'Edit'

      title: 'Edit :postTitle'
      actionTitle: 'Edit'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/blog/:slug/delete',
      controller: 'BlogDeleteCtrl'
      templateUrl: '/views/blog/postDelete.html'
      permission: 'delete blog post'
      tabTitle: 'Delete'


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
  constructor: ($scope, BlogService, Page) ->
    Page.setTitle 'Blog'
    Page.setBreadcrumbs [
      {title: 'Blog'}
    ]

    BlogService.getList().then (results) ->
      $scope.posts = results.posts


# List of recent blog posts
class BlogRecentListCtrl extends Controller
  constructor: ($scope, BlogService, Page) ->
    BlogService.getList().then (results) ->
      $scope.posts = results.posts


# Create blog post
class BlogAddCtrl extends Controller
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Page, $location, $filter) ->
    Page.setTitle 'Add blog post'
    Page.setBreadcrumbs [
      {title: 'Blog', url: '/blog'}
      {title: Page.getTitle()}
    ]
    Page.setBodyClass ['blog-post-add', 'blog-post-form']

    $scope.customUrl = false

    $scope.updateSlug = ->
      friendlySlug = $filter('friendlyUrl')($scope.post.title)
      if !$scope.customUrl
        $scope.post.slug = friendlySlug

    $scope.aceLoaded = (editor) ->
      editor.setOptions
        minLines: 5
        maxLines: 'Infinity'
        tabSize: 2
        autoScrollEditorIntoView: true
        wrap: true
        showLineNumbers: false
        showGutter: false

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
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Page, $location, $route) ->
    Page.setBodyClass ['blog-post-view']

    $scope.post = null
    $scope.showComments = false
    $scope.disqus_shortname = Config.disqus_shortname

    BlogService.getPost($routeParams.slug).then (results) ->
      # TODO: execute PageNotFound() and check if any redirects exists
      # TODO: check if redirections works with PhantomJS
      if !results then $location.path "/not-found?from=blog/#{$routeParams.slug}"

      Page.setTitle results.title
      Page.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title}
      ]
      Page.setTabs BlogHelper.getTabs results
      $scope.post = results
      $scope.showComments = true


# Edit blog post
class BlogEditCtrl extends Controller
  constructor: (BlogService, BlogHelper, Page, $scope, $routeParams, $location) ->
    BlogService.getPost($routeParams.slug).then (results) ->
      if !results then $location.path '/not-found'

      Page.setTitle "Edit #{results.title}"
      Page.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title, url: "/blog/#{results.slug}"}
        {title: 'Edit'}
      ]
      Page.setTabs BlogHelper.getTabs results
      Page.setBodyClass ['blog-post-edit', 'blog-post-form']

      $scope.post = results

    $scope.updateSlug = $scope.disableAutoUrl = ->

    $scope.aceLoaded = (editor) ->
      editor.setOptions
        minLines: 5
        maxLines: 'Infinity'
        tabSize: 2
        autoScrollEditorIntoView: true
        wrap: true
        showLineNumbers: false
        showGutter: false

    $scope.submitPost = ->
      tagsArray = []

      if $scope.post.tags?.split?
        tagsArray = $scope.post.tags.split(',')
        for tag, i in tagsArray
          tagsArray[i] = tagsArray[i].trim()

      BlogService.savePost($scope.post)
      .success (data, status, headers, config) ->
        console.log data, status
#        $location.path "/blog/#{$scope.post.slug}"
      .error (data, status, headers, config) ->
        alert angular.toJson data


# Delete blog post
class BlogDeleteCtrl extends Controller
  constructor: ($scope, $routeParams, BlogService, BlogHelper, Page, $location) ->
    Page.setBodyClass ['blog-post-delete']
    BlogService.getPost($routeParams.slug).then (results) ->
      Page.setTitle "Delete #{results.title}"
      Page.setBreadcrumbs [
        {title: 'Blog', url: '/blog'}
        {title: results.title, url: "/blog/#{results.slug}"}
        {title: 'Delete'}
      ]
      Page.setTabs BlogHelper.getTabs results

      $scope.post = results

    $scope.deletePost = ->
      BlogService.deletePost($scope.post._id).then (results) ->
        $location.path '/blog'


# Blog service
class BlogService extends Service
  endpointUrl = "#{Config.endpointUrl}/blog"

  constructor: (@$http, @$location, @Page) ->

  # Get list of blog posts
  getList: (limit = 0) ->
    @$http.get("#{endpointUrl}?limit=#{limit}")
    .then (results) ->
      results.data

  # Get single post
  getPost: (slug) ->
    baseUrl = @Page.getBaseUrl() + '/blog/'
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
