'use strict'

###*
Binds a ACE Editor widget
###
angular.module('ui.ace', []).constant('uiAceConfig', {}).directive 'uiAce', [
  'uiAceConfig'
  (uiAceConfig) ->
    throw new Error('ui-ace need ace to work... (o rly?)')  if angular.isUndefined(window.ace)

    ###*
    Sets editor options such as the wrapping mode or the syntax checker.

    @param acee
    @param session ACE editor session
    @param {object} opts Options to be set
    ###
    setOptions = (acee, session, opts) ->

      availableOptions = acee.getOptions()

      defaultOptions =
        minLines: 5
        maxLines: 'Infinity'
        tabSize: 2
        autoScrollEditorIntoView: true
        wrap: true

      supportedOptions = defaultOptions

      for optionKey, optionValue of opts
        if availableOptions.hasOwnProperty(optionKey)
          supportedOptions[optionKey] = optionValue

      acee.setOptions supportedOptions

      # commands
      if angular.isDefined(opts.disableSearch) and opts.disableSearch
        acee.commands.addCommands [
          name: 'unfind'
          bindKey:
            win: 'Ctrl-F'
            mac: 'Command-F'
          exec: ->
            false
          readOnly: true
        ]

      # onLoad callback
      opts.onLoad acee  if angular.isFunction(opts.onLoad)

      # Basic options
      acee.setTheme 'ace/theme/' + opts.theme  if angular.isString(opts.theme)
      session.setMode 'ace/mode/' + opts.mode  if angular.isString(opts.mode)
      return

    return (
      restrict: 'EA'
      require: '?ngModel'
      link: (scope, elm, attrs, ngModel) ->

        ###*
        Corresponds the uiAceConfig ACE configuration.
        @type object
        ###
        options = uiAceConfig.ace or {}

        ###*
        uiAceConfig merged with user options via json in attribute or data binding
        @type object
        ###
        opts = angular.extend({}, options, scope.$eval(attrs.uiAce))

        ###*
        ACE editor
        @type object
        ###
        acee = window.ace.edit(elm[0])

        ###*
        ACE editor session.
        @type object
        @see [EditSession]{@link http://ace.c9.io/#nav=api&api=edit_session}
        ###
        session = acee.getSession()

        ###*
        Reference to a change listener created by the listener factory.
        @function
        @see listenerFactory.onChange
        ###
        onChangeListener = undefined

        ###*
        Reference to a blur listener created by the listener factory.
        @function
        @see listenerFactory.onBlur
        ###
        onBlurListener = undefined

        ###*
        Calls a callback by checking its existing. The argument list
        is variable and thus this function is relying on the arguments
        object.
        @throws {Error} If the callback isn't a function
        ###
        executeUserCallback = ->

          ###*
          The callback function grabbed from the array-like arguments
          object. The first argument should always be the callback.

          @see [arguments]{@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions_and_function_scope/arguments}
          @type {*}
          ###
          callback = arguments[0]

          ###*
          Arguments to be passed to the callback. These are taken
          from the array-like arguments object. The first argument
          is stripped because that should be the callback function.

          @see [arguments]{@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions_and_function_scope/arguments}
          @type {Array}
          ###
          args = Array::slice.call(arguments, 1)
          if angular.isDefined(callback)
            scope.$apply ->
              if angular.isFunction(callback)
                callback args
              else
                throw new Error('ui-ace use a function as callback.')
              return

          return


        ###*
        Listener factory. Until now only change listeners can be created.
        @type object
        ###
        listenerFactory =
          onChange: (callback) ->
            (e) ->
              newValue = session.getValue()
              if newValue isnt scope.$eval(attrs.value) and not scope.$$phase and not scope.$root.$$phase
                if angular.isDefined(ngModel)
                  scope.$apply ->
                    ngModel.$setViewValue newValue
                    return

                executeUserCallback callback, e, acee
              return

          onBlur: (callback) ->
            ->
              executeUserCallback callback, acee
              return

        attrs.$observe 'readonly', (value) ->
          acee.setReadOnly value is 'true'
          return


        # Value Blind
        if angular.isDefined(ngModel)
          ngModel.$formatters.push (value) ->
            if angular.isUndefined(value) or value is null
              return ''
            else throw new Error('ui-ace cannot use an object or an array as a model')  if angular.isObject(value) or angular.isArray(value)
            value

          ngModel.$render = ->
            session.setValue ngModel.$viewValue
            return

        # set the options here, even if we try to watch later, if this
        # line is missing things go wrong (and the tests will also fail)
        setOptions acee, session, opts

        # Listen for option updates
        scope.$watch attrs.uiAce, (->
          opts = angular.extend({}, options, scope.$eval(attrs.uiAce))

          # unbind old change listener
          session.removeListener 'change', onChangeListener

          # bind new change listener
          onChangeListener = listenerFactory.onChange(opts.onChange)
          session.on 'change', onChangeListener

          # unbind old blur listener
          #session.removeListener('blur', onBlurListener);
          acee.removeListener 'blur', onBlurListener

          # bind new blur listener
          onBlurListener = listenerFactory.onBlur(opts.onBlur)
          acee.on 'blur', onBlurListener
          setOptions acee, session, opts
          return
        ), true

        # EVENTS
        onChangeListener = listenerFactory.onChange(opts.onChange)
        session.on 'change', onChangeListener
        onBlurListener = listenerFactory.onBlur(opts.onBlur)
        acee.on 'blur', onBlurListener
        elm.on '$destroy', ->
          acee.session.$stopWorker()
          acee.destroy()
          return

        scope.$watch (->
          [
            elm[0].offsetWidth
            elm[0].offsetHeight
          ]
        ), (->
          acee.resize()
          acee.renderer.updateFull()
          return
        ), true
        return
    )
]
