LessAutocompileView = require './less-autocompile-view'

module.exports =
  lessAutocompileView: null

  activate: (state) ->
    @lessAutocompileView = new LessAutocompileView(state.lessAutocompileViewState)

  deactivate: ->
    @lessAutocompileView.destroy()

  serialize: ->
    lessAutocompileViewState: @lessAutocompileView.serialize()
