sysPath = require 'path'
uglify = require 'uglify-js'
ngAnnotate = require 'ng-annotate'

clone = (obj) ->
  return obj if not obj? or typeof obj isnt 'object'
  copied = new obj.constructor()
  copied[key] = clone val for key, val of obj
  copied

module.exports = class NgAnnotateUglifyMinifier
  brunchPlugin: yes
  type: 'javascript'

  constructor: (@config) ->
    @options = (clone @config?.plugins?.uglify) or {}
    @options.fromString = yes
    @options.sourceMaps = @config?.sourceMaps

  optimize: (data, path, callback) =>
    options = @options
    options.outSourceMap = if options.sourceMaps
      "#{path}.map"
    else
      undefined

    try
      annotated = ngAnnotate(data, {add: true})
      if annotated.errors
        throw new Error annotated.errors.join("\n")
      optimized = uglify.minify(annotated.src, options)
    catch err
      error = "ng-annotate or JS minify failed on #{path}: #{err}"
    finally
      result = if optimized and options.sourceMaps
        data: optimized.code
        map: optimized.map
      else
        data: optimized.code
      callback error, (result or data)
