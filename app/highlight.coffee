class Highlight extends Service
  constructor: (@$window) ->
    return Highlight

  @highlightAuto: (code) ->
    hljs.highlightAuto code

  @highlightElement: (element) ->
    hljs.highlightBlock(element)



class code extends Directive
  constructor: ($window, Highlight) ->
    return restrict: 'E', link: ($scope, element, attrs) ->
      parent = element.parent()
      if parent.prop('tagName') is 'PRE'
        Highlight.highlightElement element[0]

        # Add line numbers
        if element.hasClass 'line-numbers'
          pl = parent.length
          for i in [0...pl]
            element.html '<span class="number"></span>' + element.html()
            num = element[i].innerHTML.split(/\n/).length - 1
            for j in [0...num]
              line_num = parent[i].getElementsByTagName('span')[0]
              line_num.innerHTML += '<span>' + (j + 1) + '</span>'


