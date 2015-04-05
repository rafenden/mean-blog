# Based on https://github.com/esvit/angular-social

# Helper function
template = (tmpl, context, filter) ->
  tmpl.replace /\{([^\}]+)\}/g, (m, key) ->
    # If key don't exists in the context we should keep template tag as is
    (if key of context then ((if filter then filter(context[key]) else context[key])) else m)

app = angular.module('ngSocial', [])

# Main directive
app.directive 'ngSocialButtons', [ '$compile', '$q', '$parse', '$http', '$location', ($compile, $q, $parse, $http, $location) ->
  restrict: 'AC'
  scope:
    url: '='
    title: '='
    description: '='
    image: '='

  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share.html'
  controller: [ '$scope', '$q', '$http', ($scope, $q, $http) ->
    getUrl = ->
      $scope.url or $location.absUrl()

    ctrl =
      init: (scope, element, options) ->
        if options.counter
          ctrl.getCount(scope.options).then (count) ->
            scope.count = count


      link: (options) ->
        options = options or {}
        urlOptions = options.urlOptions or {}
        urlOptions.url = getUrl()
        urlOptions.title = $scope.title
        urlOptions.image = $scope.image
        urlOptions.description = $scope.description or ''
        ctrl.makeUrl options.clickUrl or options.popup.url, urlOptions

      clickShare: (e, options) ->
        return  if e.shiftKey or e.ctrlKey
        e.preventDefault()
        _gaq.push [ '_trackSocial', options.track.name, options.track.action, $scope.url ]  if options.track and typeof _gaq isnt 'undefined' and angular.isArray(_gaq)
        process = true
        process = options.click.call(this, options)  if angular.isFunction(options.click)
        if process
          url = ctrl.link(options)
          ctrl.openPopup url, options.popup

      openPopup: (url, params) ->
        left = Math.round(screen.width / 2 - params.width / 2)
        top = 0
        top = Math.round(screen.height / 3 - params.height / 2)  if screen.height > params.height
        win = window.open(url, 'sl_' + @service, 'left=' + left + ',top=' + top + ',' + 'width=' + params.width + ',height=' + params.height + ',personalbar=0,toolbar=0,scrollbars=1,resizable=1')
        if win
          win.focus()
        else
          location.href = url

      getCount: (options) ->
        def = $q.defer()
        urlOptions = options.urlOptions or {}
        urlOptions.url = getUrl()
        urlOptions.title = $scope.title
        url = ctrl.makeUrl(options.counter.url, urlOptions)
        if options.counter.get
          options.counter.get url, def, $http
        else
          $http.jsonp(url).success (res) ->
            if options.counter.getNumber
              def.resolve options.counter.getNumber(res)
            else
              def.resolve res

        def.promise

      makeUrl: (url, context) ->
        template url, context, encodeURIComponent

    ctrl
  ]
]


# Facebook
app.directive 'ngSocialFacebook', ->
  options =
    counter:
      url: 'http://graph.facebook.com/fql?q=SELECT+total_count+FROM+link_stat+WHERE+url%3D%22{url}%22' + '&callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.data[0].total_count

    popup:
      url: 'http://www.facebook.com/sharer/sharer.php?u={url}'
      width: 600
      height: 500

    track:
      name: 'facebook'
      action: 'send'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-facebook'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Twitter
app.directive 'ngSocialTwitter', ->
  options =
    counter:
      url: 'http://urls.api.twitter.com/1/urls/count.json?url={url}&callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.count

    popup:
      url: 'http://twitter.com/intent/tweet?url={url}&text={title}'
      width: 600
      height: 450

    click: (options) ->

      # Add colon to improve readability
      options.pageTitle += ':'  unless /[\.:\-–—]\s*$/.test(options.pageTitle)
      true

    track:
      name: 'twitter'
      action: 'tweet'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-twitter'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# LinkedIn
app.directive 'ngSocialLinkedin', ->
  options =
    counter:
      url: 'https://www.linkedin.com/countserv/count/share?url={url}&format=jsonp&callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.count

    popup:
      url: 'http://www.linkedin.com/shareArticle?mini=true&url={url}&title={title}'
      width: 600
      height: 450

    click: (options) ->
      # Add colon to improve readability
      options.pageTitle += ':'  unless /[\.:\-–—]\s*$/.test(options.pageTitle)
      true

    track:
      name: 'linkedin'
      action: 'share article'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-twitter'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Google Plus (no counter)
app.directive 'ngSocialGooglePlus', [ '$parse', ($parse) ->
  options =
    popup:
      url: 'https://plus.google.com/share?url={url}'
      width: 700
      height: 500

    track:
      name: 'Google+'
      action: 'share'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-google-plus'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options
]

# vk.com
app.directive 'ngSocialVk', ->
  options =
    counter:
      url: 'http://vkontakte.ru/share.php?act=count&url={url}&index={index}'
      get: (jsonUrl, deferred, $http) ->
        unless options._
          options._ = []
          window.VK = {}  unless window.VK
          window.VK.Share = count: (idx, number) ->
            options._[idx].resolve number
        index = options._.length
        options._.push deferred
        $http.jsonp jsonUrl.replace('{index}', index)

    popup:
      url: 'http://vk.com/share.php?url={url}&title={title}&description={description}&image={image}'
      width: 550
      height: 330

    track:
      name: 'VKontakte'
      action: 'share'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-vk'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Odnoklassniki
angular.module('ngSocial').directive 'ngSocialOdnoklassniki', ->
  options =
    counter:
      url: 'http://www.odnoklassniki.ru/dk?st.cmd=shareData&ref={url}&cb=JSON_CALLBACK'
      getNumber: (data) ->
        data.count

    popup:
      url: 'http://www.odnoklassniki.ru/dk?st.cmd=addShare&st._surl={url}'
      width: 550
      height: 360

    track:
      name: 'Odnoklassniki'
      action: 'share'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-odnoklassniki'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Mail.ru
angular.module('ngSocial').directive 'ngSocialMailru', ->
  options =
    counter:
      url: 'http://connect.mail.ru/share_count?url_list={url}&callback=1&func=JSON_CALLBACK'
      getNumber: (data) ->
        for url of data
          return data[url].shares  if data.hasOwnProperty(url)

    popup:
      url: 'http://connect.mail.ru/share?share_url={url}&title={title}'
      width: 550
      height: 360

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-mailru'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Pinterest
angular.module('ngSocial').directive 'ngSocialPinterest', ->
  options =
    counter:
      url: 'http://api.pinterest.com/v1/urls/count.json?url={url}&callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.count

    popup:
      url: 'http://pinterest.com/pin/create/button/?url={url}&description={title}'
      width: 630
      height: 270

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-pinterest'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Github forks
angular.module('ngSocial').directive 'ngSocialGithubForks', ->
  options =
    counter:
      url: 'https://api.github.com/repos/{user}/{repository}?callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.data.forks_count

    clickUrl: 'https://github.com/{user}/{repository}/'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-github ng-social-github-forks'
    return unless ctrl
    options.urlOptions =
      user: attrs.user
      repository: attrs.repository

    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# Github
angular.module('ngSocial').directive 'ngSocialGithub', ->
  options =
    counter:
      url: 'https://api.github.com/repos/{user}/{repository}?callback=JSON_CALLBACK'
      getNumber: (data) ->
        data.data.watchers_count

    clickUrl: 'https://github.com/{user}/{repository}/'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  controller: ($scope) ->

  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-github'
    return unless ctrl
    options.urlOptions =
      user: attrs.user
      repository: attrs.repository

    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options


# StumbleUpon (no counter)
app.directive 'ngSocialStumbleupon', [ '$parse', ($parse) ->
  options =
    popup:
      url: 'http://www.stumbleupon.com/submit?url={url}&title={title}'
      width: 800
      height: 600

    track:
      name: 'StumbleUpon'
      action: 'share'

  restrict: 'C'
  require: '^?ngSocialButtons'
  scope: true
  replace: true
  transclude: true
  templateUrl: '/views/partials/social-share-button.html'
  link: (scope, element, attrs, ctrl) ->
    element.addClass 'ng-social-stumbleupon'
    return unless ctrl
    scope.options = options
    scope.ctrl = ctrl
    ctrl.init scope, element, options
]
