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

  truncate: (str, chars, suffix, left) ->
    suffix = if 'string' == typeof chars then chars else suffix
    chars = if 'number' == typeof chars then chars else 200

    suffix = suffix || ''

    if !str || !str.length || str.length <= chars
      return str

    left = left isnt false
    mod = if left then false else true
    end = if mod then str.length - chars else chars
    safe = if mod then str.length else 0
    newStr = str.substring(safe, end)
    perfect = if left then str[end] == ' ' else (str[end - 1] == ' ');

    if !perfect
      safe = if left then /\s*[^\s|.]*$/ else /^[^\s|.]*\s*/
      newStr = newStr.replace(safe, '')

    return if left then newStr + suffix else suffix + newStr

  compileLess: (filePath) ->
    fs = require 'fs'
    less = require 'less'
    path = require 'path'

    compile = (params) =>
      if params.out is false
        return

      @showOverlay()

      parser = new less.Parser
        paths: [path.dirname path.resolve(params.file, params.out)]
        filename: path.basename params.file

      fs.readFile params.file, (error, data) =>
        parser.parse data.toString(), (error, tree) =>
          truncateFilePath = @truncate(filePath, 70, '..', false)

          @addMessageOverlay 'icon-file-text', 'info', truncateFilePath

          if error
            truncateFilenameError = @truncate(error.filename, 70, '..', false)

            @addMessageOverlay '', 'error', error.message + ' : ' + truncateFilenameError
          else
            css = tree.toCSS
              compress: params.compress

            newFile = path.resolve(path.dirname(params.file), params.out)
            newPath = path.dirname newFile

            @writeFile css, newFile, newPath, =>
              truncateNewFile = @truncate(newFile, 70, '..', false)

              @addMessageOverlay 'icon-file-symlink-file', 'success', truncateNewFile

          @hideOverlay()

    @getParams filePath, (params) ->
      compile params
