{View, $, $$} = require 'atom'

module.exports =
class LessAutocompileView extends View
  @content: ->
    @div class: 'less-autocompile overlay from-bottom hide', =>
      @span class: 'inline-block loading loading-spinner-tiny hide'
      @div class: 'package-name', =>
        @span 'LESS AutoCompile', class: 'inline-block highlight'
      @ul class: 'list-tree'

  initialize: (serializeState) ->
    @timeout = null
    @messageListTree = @find('.list-tree')
    @messageLoading = @find('.loading')

    atom.workspaceView.on 'core:save', (e) =>
      @compile atom.workspace.activePaneItem

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  compile: (editor) ->
    path = require 'path'

    filePath = editor.getUri()
    fileExt = path.extname filePath

    if fileExt == '.less'
      @compileLess filePath

  getParams: (filePath, callback) ->
    fs = require 'fs'
    path = require 'path'
    readline = require 'readline'

    params =
      file: filePath
      compress: false
      main: false
      out: false

    parse = (firstLine) =>
      firstLine.split(',').forEach (item) ->
        i = item.indexOf ':'

        if i < 0
          return

        key = item.substr(0, i).trim()
        match = /^\s*\/\/\s*(.+)/.exec(key);

        if match
          key = match[1]

        value = item.substr(i + 1).trim()

        params[key] = value

      if params.main isnt false
        @getParams path.resolve(path.dirname(filePath), params.main), callback
      else
        callback params

    rl = readline.createInterface
      input: fs.createReadStream filePath
      output: process.stdout
      terminal: false

    firstLine = null

    rl.on 'line', (line) ->
      if firstLine is null
        firstLine = line
        parse firstLine

  writeFile: (contents, newFile, newPath, callback) ->
    fs = require 'fs'
    mkdirp = require 'mkdirp'

    mkdirp newPath, (error) ->
      fs.writeFile newFile, contents, callback

  addMessageOverlay: (icon, typeMessage, message)->
    @messageListTree.append $$ ->
      @li class: 'list-item', =>
        @span class: "icon #{icon} text-#{typeMessage}", message

  showOverlay: ->
    @messageListTree.empty()
    @messageLoading.removeClass 'hide'

    atom.workspaceView.append this

    @removeClass 'hide'

    clearTimeout @timeout

    setTimeout =>
      @addClass 'animate'
    , 1

  hideOverlay: ->
    @messageLoading.addClass 'hide'

    @timeout = setTimeout =>
      @removeClass 'animate'

      setTimeout =>
        @addClass 'hide'
      , 400
    , 3000

  compileLess: (filePath) ->
    fs = require 'fs'
    less = require 'less'
    path = require 'path'
    sugar = require 'sugar'

    compile = (params) =>
      if params.out is false
        return

      @showOverlay()

      parser = new less.Parser
        paths: [path.dirname path.resolve(params.file, params.out)]
        filename: path.basename params.file

      fs.readFile params.file, (error, data) =>
        parser.parse data.toString(), (error, tree) =>
          @addMessageOverlay 'icon-file-text', 'info', filePath.truncate(50, 'left')

          if error
            @addMessageOverlay '', 'error', error.message + ' : ' + error.filename.truncate(50, 'left')
          else
            css = tree.toCSS
              compress: params.compress

            newFile = path.resolve(path.dirname(params.file), params.out)
            newPath = path.dirname newFile

            @writeFile css, newFile, newPath, =>
              @addMessageOverlay 'icon-file-symlink-file', 'success', newFile.truncate(50, 'left')

          @hideOverlay()

    @getParams filePath, (params) ->
      compile params
