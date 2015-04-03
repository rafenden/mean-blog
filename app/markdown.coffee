class MarkdownConverter extends Provider
  constructor: ->
    @opts = {}

    @config = (newOpts) ->
      @opts = newOpts

    @$get = ->
      new Showdown.converter @opts

class markdown extends Directive
  constructor: (MarkdownConverter, $compile) ->
    return restrict: 'A', link: ($scope, element, $attrs) ->
      $attrs.$observe 'markdown', (newValue) ->
        element.html ''
        if newValue
          html = MarkdownConverter.makeHtml newValue
          convertedHtml = $compile(html)($scope)
          element.append convertedHtml


class markdownFilter extends Filter
  constructor: ($sce) ->
    return (value) ->
      converter = new Showdown.converter()
      $sce.trustAsHtml converter.makeHtml value ? ''
