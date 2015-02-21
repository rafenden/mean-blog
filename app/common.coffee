class a extends Directive
  constructor: ($location, Page) ->
    return restrict: 'E', link: ($scope, element, attrs) ->
      className = attrs.activeLink ? 'active'
      path = attrs.href ? attrs['ng-href']
      $scope.location = location

      $scope.$on '$routeChangeSuccess', (event, current, previous) ->
        pathToCheck = $location.path() || "current $location.path doesn't reach this level"
        tabLink = attrs.href || "href doesn't include this level"

        parent = element.parent()
        if parent.prop('tagName') isnt 'LI' then parent = null

        # Check for active link
        if (tabLink isnt '/' and pathToCheck.indexOf(tabLink) is 0) or (tabLink is '/' and pathToCheck is '/')
          element.addClass 'active'
          parent.addClass 'active' if parent
        else if element.hasClass 'active'
          element.removeClass 'active'
          parent.removeClass 'active' if parent


class img extends Directive
  constructor: () ->
    return restrict: 'E', link: ($scope, element, attrs) ->
      if attrs.src? and attrs.src.indexOf '/images/' is 0
        element.attr 'src', attrs.src.replace '/images', Config.imagesCdn


class friendlyUrl extends Filter
  constructor: ->
    return (text, separator = '-', lowercase = true) ->
      output = undefined
      q_separator = undefined
      translation = {}
      tags = undefined
      commentsAndPhpTags = undefined
      key = undefined
      replacement = undefined
      leadingTrailingSeparators = undefined

      #escape all possible regex characters in the separator to create a "searchable" separator
      #equivalent to preg_quote in php
      q_separator = separator.replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\-]', 'g'), '\\$&')

      #regex to replacement object
      translation['&.+?;'] = '' #remove html entities
      translation['[^a-z0-9 _-]'] = '' #remove anything other than alphanumeric, spaces, underscores and dashes
      translation['\\s+'] = separator #change whitespace to separator (regexp requires extra escaping of backslashes)
      translation['(' + q_separator + ')+'] = separator #change escaped separator to separator

      #strip html tags from the title
      tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/g
      commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/g
      output = text.replace(commentsAndPhpTags, '').replace(tags, '')

      #change!
      for key of translation
        replacement = translation[key]
        key = new RegExp(key, 'ig')
        output = output.replace(key, replacement)

      #lowercase the title if necessary
      output = output.toLowerCase() if lowercase

      #trim leading and trailing separators in case there was multiple spaces
      leadingTrailingSeparators = new RegExp('^' + q_separator + '+|' + q_separator + '+$')
      output = output.replace(leadingTrailingSeparators, '')

      #es5 trim out whitespace, make sure to polyfill this for older browsers
      output = output.trim()
      output


# Based on https://github.com/michaelbromley/angularUtils/tree/master/src/directives/disqus
class disqus extends Directive
  link: (scope) ->
    # ensure that the disqus_identifier and disqus_url are both set, otherwise we will run in to identifier conflicts when using URLs with "#" in them
    # see http://help.disqus.com/customer/portal/articles/662547-why-are-the-same-comments-showing-up-on-multiple-pages-
    if typeof scope.disqus_identifier == 'undefined' or typeof scope.disqus_url == 'undefined'
      throw 'Please ensure that the `disqus-identifier` and `disqus-url` attributes are both set.'
    scope.$watch 'readyToBind', (isReady) ->
      # If the directive has been called without the 'ready-to-bind' attribute, we
      # set the default to "true" so that Disqus will be loaded straight away.
      if !angular.isDefined(isReady)
        isReady = 'true'
      if scope.$eval(isReady)
        # put the config variables into separate global vars so that the Disqus script can see them
        $window.disqus_shortname = scope.disqus_shortname
        $window.disqus_identifier = scope.disqus_identifier
        $window.disqus_title = scope.disqus_title
        $window.disqus_url = scope.disqus_url
        $window.disqus_category_id = scope.disqus_category_id
        $window.disqus_disable_mobile = scope.disqus_disable_mobile
        # get the remote Disqus script and insert it into the DOM, but only if it not already loaded (as that will cause warnings)
        if !$window.DISQUS
          dsq = document.createElement('script')
          dsq.type = 'text/javascript'
          dsq.async = true
          dsq.src = '//' + scope.disqus_shortname + '.disqus.com/embed.js'
          (document.getElementsByTagName('head')[0] or document.getElementsByTagName('body')[0]).appendChild dsq
        else
          $window.DISQUS.reset
            reload: true
            config: ->
              @page.identifier = scope.disqus_identifier
              @page.url = scope.disqus_url
              @page.title = scope.disqus_title
  constructor: ($window) ->
    return {
      restrict: 'E'
      scope:
        disqus_shortname: '@disqusShortname'
        disqus_identifier: '@disqusIdentifier'
        disqus_title: '@disqusTitle'
        disqus_url: '@disqusUrl'
        disqus_category_id: '@disqusCategoryId'
        disqus_disable_mobile: '@disqusDisableMobile'
        readyToBind: '@'
      template: '<div id="disqus_thread"></div>'
      link: (scope) ->
        # ensure that the disqus_identifier and disqus_url are both set, otherwise we will run in to identifier conflicts when using URLs with "#" in them
        # see http://help.disqus.com/customer/portal/articles/662547-why-are-the-same-comments-showing-up-on-multiple-pages-
        scope.$watch 'readyToBind', (isReady) ->
          # If the directive has been called without the 'ready-to-bind' attribute, we
          # set the default to "true" so that Disqus will be loaded straight away.
          if !angular.isDefined(isReady)
            isReady = 'true'
          if scope.$eval(isReady)
            # put the config variables into separate global vars so that the Disqus script can see them
            $window.disqus_shortname = scope.disqus_shortname
            $window.disqus_identifier = scope.disqus_identifier
            $window.disqus_title = scope.disqus_title
            $window.disqus_url = scope.disqus_url
            $window.disqus_category_id = scope.disqus_category_id
            $window.disqus_disable_mobile = scope.disqus_disable_mobile

            scope.$watch 'scope.disqus_identifier', (value) ->
              $window.disqus_identifier = value
              
            # get the remote Disqus script and insert it into the DOM, but only if it not already loaded (as that will cause warnings)
            if !$window.DISQUS
              dsq = document.createElement('script')
              dsq.type = 'text/javascript'
              dsq.async = true
              dsq.src = '//' + scope.disqus_shortname + '.disqus.com/embed.js'
              (document.getElementsByTagName('head')[0] or document.getElementsByTagName('body')[0]).appendChild dsq
            else
              $window.DISQUS.reset
                reload: true
                config: ->
                  @page.identifier = scope.disqus_identifier
                  @page.url = scope.disqus_url
                  @page.title = scope.disqus_title
    }


class disqusCount extends Directive
  constructor: ($window) ->
    return {
      restrict: 'EAC'
      scope:
        disqus_shortname: '@disqusShortname'
        disqus_identifier: '@disqusIdentifier'
        disqus_title: '@disqusTitle'
        disqus_url: '@disqusUrl'
        disqus_category_id: '@disqusCategoryId'
        disqus_disable_mobile: '@disqusDisableMobile'
        readyToBind: '@'
      template: '<div id="disqus_thread"></div>'
      link: (scope) ->
        
    }

class addthisToolbox extends Directive
  constructor: ($timeout) ->
    return {
      restrict : 'A'
      transclude : true
      replace : true
      template : '<div ng-transclude></div>'
      link : ($scope, element, attrs) ->
        $timeout ->
          addthis.init()
          addthis.toolbox $(element).get(), {},
            url: attrs.url,
            title: "My Awesome Blog",
            description: 'Checkout this awesome post on blog.me'
    }
