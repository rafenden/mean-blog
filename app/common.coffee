class a extends Directive
  constructor: ($location, Site) ->
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


# TODO: Create Showdown plugin instead of a directive.
class img extends Directive
  constructor: () ->
    return restrict: 'E', link: ($scope, element, attrs) ->
      if attrs.src? and attrs.src.indexOf '/content-images/' is 0
        element.attr 'src', attrs.src.replace '/content-images', Config.imagesCdn
      # Add captions to images.
      if attrs.title?
        element.after "<div class=\"image-caption\">#{attrs.title}</div>"


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


class popup extends Directive
  constructor: ->
    return {
    restrict: 'EA'
    link: (scope, element, attrs) ->
      if attrs.popup? and attrs.popup isnt 'popup'
        dimensions = attrs.popup.split 'x'
      else
        dimensions = [500, 400]

      width = dimensions[0]
      height = dimensions[1]
      element.attr 'target', 'popup'

      element.on 'click', (event) ->
        event.preventDefault()
        popupWindow = window.open(this.href, 'popup', "toolbars=0,scrollbars=1,location=0,statusbars=0,menubars=0,resizable=1,width=#{width},height=#{height},left=50,top=50")
        popupWindow.focus()
    }

class card3d extends Directive
  constructor: ($document, $window) ->
    return {
    restrict: 'AC'
    link: (scope, element, attrs) ->
      angular.element($document[0].body).on 'mousemove', (event) ->
        ax = -($window.innerWidth / 4 - event.pageX) / 15
        ay = (($window.innerHeight / 4 - event.pageY) / 10) - 20

        element.css
          'transform': "rotateY(#{ax}deg) rotateX(#{ay}deg)"
          '-webkit-transform': "rotateY(#{ax}deg) rotateX(#{ay}deg)"
          '-moz-transform': "rotateY(#{ax}deg) rotateX(#{ay}deg)"
    }


# Makes big numbers into short format. 1 million becomes 1m and 1122 becomes 1.1k
# Based on https://gist.github.com/Chocksy/7202086
class humanNumber extends Filter
  constructor: ->
    return (number) ->
      if number?
        abs = Math.abs(number)
        if abs >= Math.pow(10, 12)
          # trillion
          number = (number / Math.pow(10, 12)).toFixed(1) + 't'
        else if abs < Math.pow(10, 12) and abs >= Math.pow(10, 9)
          # billion
          number = (number / Math.pow(10, 9)).toFixed(1) + 'b'
        else if abs < Math.pow(10, 9) and abs >= Math.pow(10, 6)
          # million
          number = (number / Math.pow(10, 6)).toFixed(1) + 'm'
        else if abs < Math.pow(10, 6) and abs >= Math.pow(10, 3)
          # thousand
          number = (number / Math.pow(10, 3)).toFixed(1) + 'k'
        number

