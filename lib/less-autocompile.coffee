LessAutocompileView = require './less-autocompile-view'

module.exports =
  lessAutocompileView: null
  config:
    compressCss:
      title: 'Compress CSS'
      description: 'Choose if your CSS will be compressed or not.'
      type: 'boolean'
      default: false
    makeSourceMap:
      title: 'Source Map'
      description: 'Choose if your CSS Source map will be generated or not.'
      type: 'boolean'
      default: true

  activate: (state) ->
    @lessAutocompileView = new LessAutocompileView(state.lessAutocompileViewState)

  deactivate: ->
    @lessAutocompileView.destroy()

  serialize: ->
    lessAutocompileViewState: @lessAutocompileView.serialize()
