# Routes
class ProjectRoutes extends Config
  constructor: ($routeProvider) ->
    $routeProvider
    .when '/projects',
      controller: 'ProjectListCtrl'
      templateUrl: '/views/projects/projectList.html'
    .when '/projects/add',
      controller: 'ProjectAddCtrl'
      templateUrl: '/views/projects/projectForm.html'
      permission: 'add project'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/projects/:slug',
      controller: 'ProjectViewCtrl'
      templateUrl: '/views/projects/projectView.html'
      tabTitle: 'View'
    .when '/projects/:slug/edit',
      controller: 'ProjectEditCtrl'
      templateUrl: '/views/projects/projectForm.html'
      permission: 'edit project'
      tabTitle: 'Edit'
      resolve: ['angularLoad', (angularLoad) ->
        angularLoad.loadScript '//cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js'
      ]
    .when '/projects/:slug/delete',
      controller: 'ProjectDeleteCtrl'
      templateUrl: '/views/projects/projectDelete.html'
      permission: 'delete project'
      tabTitle: 'Delete'

# Project controller
class ProjectHelper extends Factory
  constructor: ->
    return ProjectHelper

  @getTabs: (post) ->
    [
      {title: 'View', url: "/projects/#{post.slug}"}
      {title: 'Edit', url: "/projects/#{post.slug}/edit"}
      {title: 'Delete', url: "/projects/#{post.slug}/delete"}
    ]


# List of projects
class ProjectListCtrl extends Controller
  constructor: ($scope, ProjectService, Page) ->
    Page.setTitle 'Projects'
    Page.setBreadcrumbs [
      {title: 'Projects'}
    ]

    ProjectService.getList().then (results) ->
      $scope.posts = results.posts

# List of recent projects
class ProjectRecentListCtrl extends Controller
  constructor: ($scope, ProjectService, Page) ->
    ProjectService.getList().then (results) ->
      $scope.posts = results.posts

# Create project
class ProjectAddCtrl extends Controller
  constructor: ($scope, $routeParams, ProjectService, ProjectHelper, Page, $location, $filter) ->
    # $filter('linky')(text, target)
    Page.setTitle 'Add project'
    Page.setBreadcrumbs [
      {title: 'Projects', url: '/projects'}
      {title: Page.getTitle()}
    ]

    $scope.submitPost = ->
#      angular.element('input, select, textarea').forEach ->
#      $('').each(function() { $(this).trigger('input'); });
      ProjectService.createPost($scope.post).then (results) ->
        $location.path '/projects'

# View project
class ProjectViewCtrl extends Controller
  constructor: ($scope, $routeParams, ProjectService, ProjectHelper, Page) ->
    ProjectService.getPost($routeParams.slug).then (results) ->
      Page.setTitle results.title
      Page.setBreadcrumbs [
        {title: 'Projects', url: '/projects'}
        {title: results.title}
      ]
      Page.setTabs ProjectHelper.getTabs results

      $scope.post = results

# Edit project
class ProjectEditCtrl extends Controller
  constructor: (ProjectService, ProjectHelper, Page, $scope, $routeParams, $location) ->
    ProjectService.getPost($routeParams.slug).then (results) ->
      Page.setTitle "Edit #{results.title}"
      Page.setBreadcrumbs [
        {title: 'Projects', url: '/projects'}
        {title: results.title, url: "/projects/#{results.slug}"}
        {title: 'Edit'}
      ]
      Page.setTabs ProjectHelper.getTabs results

      $scope.post = results

    $scope.submitPost = ->
      ProjectService.savePost($scope.post).then (results) ->
        $location.path "/projects/#{$scope.post.slug}"

# Delete project
class ProjectDeleteCtrl extends Controller
  constructor: ($scope, $routeParams, ProjectService, ProjectHelper, Page, $location) ->
    ProjectService.getPost($routeParams.slug).then (results) ->
      Page.setTitle "Delete #{results.title}"
      Page.setBreadcrumbs [
        {title: 'Projects', url: '/projects'}
        {title: results.title, url: "/projects/#{results.slug}"}
        {title: 'Delete'}
      ]
      Page.setTabs ProjectHelper.getTabs results

      $scope.post = results

    $scope.deletePost = ->
      ProjectService.deletePost($scope.post._id).then (results) ->
        $location.path '/projects'


## Project post factory
#class ProjectPost extends Factory
#  constructor: ->
#    return class
#      constructor: (@id, @title, @text, @slug, @updatedAt, @createdAt) ->

# Project service
class ProjectService extends Service
  endpointUrl = "#{Config.endpointUrl}/projects"

  constructor: (@$http) ->

  getList: (limit = 0) ->
    @$http.get("#{endpointUrl}?limit=#{limit}")
    .then (results) ->
      results.data

  getPost: (slug) ->
    @$http.get("#{endpointUrl}?slug=#{slug}")
    .then (results) ->
      results.data.posts[0]

  savePost: (post) ->
#    console.log post
    @$http.put("#{endpointUrl}/#{post._id}", post)
    .error (results, status) ->
      {results, status}

  createPost: (post) ->
#    console.log post
    @$http.post("#{endpointUrl}", post)
    .error (results, status) ->
      {results, status}

  deletePost: (id) ->
#    console.log id
    @$http.delete("#{endpointUrl}/#{id}")
    .error (results, status) ->
      {results, status}
