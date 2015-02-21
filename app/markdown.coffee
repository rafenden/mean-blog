class MarkdownConverter extends Provider
  constructor: ->
    @opts = {}

    @config = (newOpts) ->
      @opts = newOpts

    @$get = ->
      new Showdown.converter @opts

class markdown extends Directive
  constructor: (MarkdownConverter, $compile) ->
    return restrict: 'AE', link: ($scope, element, attrs) ->
      if attrs.markdown
        $scope.$watch attrs.markdown, (newVal) ->
          html = if newVal then MarkdownConverter.makeHtml(newVal) else ''
          converdetHtml = $compile(html)($scope);
          element.html ''
          element.append converdetHtml
      else
        html = MarkdownConverter.makeHtml element.html()
        element.html html

class markdownFilter extends Filter
  constructor: ($sce, $compile) ->
    return (value) ->
      converter = new Showdown.converter()
      $sce.trustAsHtml converter.makeHtml value ? ''
