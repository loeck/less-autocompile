lessCompilerProcess = null

module.exports =
  activate: (state) ->
    LessCompilerProcess = require './less-compiler-process'
    lessCompilerProcess = new LessCompilerProcess()
    lessCompilerProcess.initialize()

  deactivate: ->
    lessCompilerProcess?.destroy()
    lessCompilerProcess = null
