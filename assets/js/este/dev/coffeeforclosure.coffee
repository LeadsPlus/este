###*
  @fileoverview Fix CoffeeScript compiled code for Closure Compiler.

  Note
    It's experimental stuff. Not ready for production yet.

  todo
    nenahrazovat ve strinzich..
    make it less brittle to omit search in strings and comments

###
goog.provide 'este.dev.coffeeForClosure'
goog.provide 'este.dev.CoffeeForClosure'

###*
  @param {string} source
###
este.dev.coffeeForClosure = (source) ->
  coffeeForClosure = new este.dev.CoffeeForClosure source
  coffeeForClosure.fix()

###*
  @param {string} source
  @constructor
###
este.dev.CoffeeForClosure = (@source) ->
  # consider newlines canonization
  # str.replace(/(\r\n|\r|\n)/g, '\n');
  return

goog.scope ->
  `var _ = este.dev.CoffeeForClosure`

  ###*
    @type {string}
    @protected
  ###
  _::source

  ###*
    @return {string}
  ###
  _::fix = ->

    source = null
    loop
      className = @getClassName()
      break if !className || source == @source
      source = @source

      superClass = @getSuperClass className
      if superClass
        @removeCoffeeExtends className
        @removeInjectedExtendsCode className
      else
        @removeClassVar className
      
      namespace = @getNamespaceFromWrapper className
      @fullQualifyProperties className, namespace
      @fullQualifyConstructor className, namespace
      
      if superClass
        @addGoogInherits className, namespace, superClass
        @fixSuperClassReference()
      
      @removeWrapper className, namespace, superClass

    @addNote()
    @source

  ###*
    @return {string|undefined}
  ###
  _::getClassName = ->
    @source.match(/function ([A-Z][\w]*)/)?[1]

  ###*
    @param {string} className
    @return {string}
  ###
  _::getSuperClass = (className) ->
    regex = new RegExp "return #{className};[\\s]*\\}\\)\\((\\w+)\\);"
    matches = @source.match regex
    return '' if !matches
    matches[1]

  ###*
    @param {string} className
  ###
  _::removeCoffeeExtends = (className) ->
    regex = new RegExp "__extends\\(#{className}, _super\\);", 'g'
    @remove regex

  ###*
    @param {string} className
  ###
  _::removeInjectedExtendsCode = (className) ->
    @remove """
      var #{className},
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };"""
    
    @remove """
      var __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };"""

  ###*
    @param {string} className
  ###
  _::removeClassVar = (className) ->
    regex = new RegExp "var #{className};", 'g'
    @remove regex

  ###*
    @param {string|RegExp} value
    @protected
  ###
  _::remove = (value) ->
    @replace value, ''

  ###*
    @param {string|RegExp} value
    @param {string|Function} string
    @protected
  ###
  _::replace = (value, string) ->
    @source = @source.replace value, string

  ###*
    @param {string} className
    @return {string}
  ###
  _::getNamespaceFromWrapper = (className) ->
    regex = new RegExp "#{className} = \\(function\\((_super)?\\) \\{"
    index = @source.search regex
    return '' if index == -1
    letters = []
    while letter = @source.charAt --index
      break if letter in [' ', ';', '\n']
      letters.unshift letter
    letters.join ''
    
  ###*
    @param {string} className
    @param {string} namespace
  ###
  _::fullQualifyProperties = (className, namespace) ->
    regex = new RegExp className + '\\.(\\w+)', 'g'
    @replace regex, (match, prop) ->
      return match if prop == '__super__'
      namespace + match

  ###*
    @param {string} className
    @param {string} namespace
  ###
  _::fullQualifyConstructor = (className, namespace) ->
    regex = new RegExp "function #{className}", 'g'
    if namespace
      @replace regex, namespace + className + ' = function'
    else
      @replace regex, 'var ' + className + ' = function'

  ###*
    @param {string} className
    @param {string} namespace
    @param {string} superClass
    @protected
  ###
  _::addGoogInherits = (className, namespace, superClass) ->
    # match constructor
    regex = new RegExp "#{namespace}#{className} = function\\(", 'g'
    index = @source.search regex
    return if index == -1
    # look for position after constructor
    # a bit tricky, because functions can contain everything
    # luckily, indentation helps us
    lines = @source.slice(index).split '\n'

    for line, i in lines
      index += line.length + 1
      break if line == '  }'

    inherits = "\n  goog.inherits(#{className}, #{superClass});\n"
    @source = @source.slice(0, index) + inherits + @source.slice index

  ###*
    @protected
  ###
  _::fixSuperClassReference = ->
    @replace /__super__/g, 'superClass_'

  ###*
    @param {string} className
    @param {string} namespace
    @param {string} superClass
  ###
  _::removeWrapper = (className, namespace, superClass) ->
    # intro
    regex = new RegExp "#{namespace}#{className} = \\(function\\((_super)?\\) \\{"
    @remove regex
    # outro
    regex = new RegExp "return #{className};[\\s]*\\}\\)\\((#{superClass})?\\);", 'g'
    @remove regex

  ###*
    @protected
  ###
  _::addNote = ->
    # @source = "Fixed " + @source
    @source = "// Fixed coffee code for Closure Compiler by este dev stack\n" + @source
  
  return

exports.coffeeForClosure = este.dev.coffeeForClosure





