LessAutocompileView   = require './less-autocompile-view'
{CompositeDisposable} = require 'atom'

module.exports = LessAutocompile =
  lessAutocompileView: null

  activate: (state) ->
    @lessAutocompileView = new LessAutocompileView(state.lessAutocompileViewState)

  deactivate: ->
    @lessAutocompileView.destroy()

  serialize: ->
    lessAutocompileViewState: @lessAutocompileView.serialize()
