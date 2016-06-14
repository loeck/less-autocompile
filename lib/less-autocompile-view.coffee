async    = require 'async'
fs       = require 'fs'
less     = require 'less'
mkdirp   = require 'mkdirp'
path     = require 'path'
readline = require 'readline'

{CompositeDisposable} = require 'atom'

LessGrammar = atom.grammars.grammarForScopeName 'source.css.less'

module.exports =
class LessAutocompileView
  constructor: (serializeState) ->
    disposables = new CompositeDisposable()
    disposables.add atom.workspace.observeTextEditors (textEditor) =>
      if textEditor.getGrammar() != LessGrammar
        return
      textEditorDisposable = new CompositeDisposable(
        textEditor.onDidSave =>
          @handleSave textEditor
        textEditor.onDidDestroy ->
          textEditorDisposable.dispose()
          disposables.remove textEditorDisposable
          return
      )
      disposables.add textEditorDisposable
      return

  serialize: ->

  destroy: ->

  handleSave: (@textEditor = atom.workspace.getActiveTextEditor()) ->
    if @textEditor
      @filePath = @textEditor.getURI()
      @fileExt = path.extname @filePath

      if @fileExt == '.less'
        @getParams @filePath, (params) =>
          @compileLess params

  writeFiles: (output, newPath, newFile) ->
    async.series
      css: (callback) =>
        if output.css
          @writeFile output.css, newPath, newFile, ->
            callback null, newFile
        else
          callback null, null
      map: (callback) =>
        if output.map
          newFile = "#{newFile}.map"

          @writeFile output.map, newPath, newFile, ->
            callback null, newFile
        else
          callback null, null
    , (err, results) ->
      if err
        atom.notifications.addError err,
          dismissable: true
      else
        if results.map != null
          atom.notifications.addSuccess "Files created",
            detail: "#{results.css}\n#{results.map}"
        else
          atom.notifications.addSuccess "File created",
            detail: results.css

  writeFile: (contentFile, newPath, newFile, callback) ->
    mkdirp newPath, (err) ->
      if err
        atom.notifications.addError err,
          dismissable: true
      else
        fs.writeFile newFile, contentFile, callback

  compileLess: (params) ->
    return if !params.out

    firstLine = true
    contentFile = []
    optionsLess =
      paths: [path.dirname path.resolve(params.file)]
      filename: path.basename params.file
      compress: if params.compress == 'true' then true else false
      sourceMap: if params.sourcemap == 'true' then {} else false

    rl = readline.createInterface
      input: fs.createReadStream params.file
      terminal: false

    rl.on 'line', (line) ->
      if !firstLine
        contentFile.push line

      firstLine = false

    rl.on 'close', =>
      @renderLess params, contentFile, optionsLess

  renderLess: (params, contentFile, optionsLess) ->
    contentFile = contentFile.join "\n"

    less.render contentFile, optionsLess
      .then (output) =>
        newFile = path.resolve(path.dirname(params.file), params.out)
        newPath = path.dirname newFile

        @writeFiles output, newPath, newFile
    , (err) ->
      if err
        atom.notifications.addError err.message,
          detail: "#{err.filename}:#{err.line}"
          dismissable: true

  getParams: (filePath, callback) ->
    if !fs.existsSync filePath
      atom.notifications.addError "#{filePath} not exist",
        dismissable: true

      return

    @params =
      file: filePath

    @firstLine = true

    rl = readline.createInterface
      input: fs.createReadStream filePath
      terminal: false

    rl.on 'line', (line) =>
      @parseFirstLine line

    rl.on 'close', =>
      if @params.main
        @getParams path.resolve(path.dirname(filePath), @params.main), callback
      else
        callback @params

  parseFirstLine: (line) ->
    return if !@firstLine

    @firstLine = false

    line.split(',').forEach (item) =>
      i = item.indexOf ':'

      if i < 0
        return

      key = item.substr(0, i).trim()
      match = /^\s*\/\/\s*(.+)/.exec(key)

      if match
        key = match[1]

      value = item.substr(i + 1).trim()

      @params[key] = value
