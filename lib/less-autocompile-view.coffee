async    = require 'async'
fs       = require 'fs'
less     = require 'less'
mkdirp   = require 'mkdirp'
path     = require 'path'
readline = require 'readline'

module.exports =
class LessAutocompileView
  constructor: (serializeState) ->
    atom.commands.add 'atom-workspace', 'core:save': => @handleSave()

  serialize: ->

  destroy: ->

  handleSave: ->
    @activeEditor = atom.workspace.getActiveTextEditor()

    if @activeEditor
      @filePath = @activeEditor.getURI()
      @fileExt = path.extname @filePath

      if @fileExt == '.less'
        @getParams @filePath, (params) =>
          if params.main
            @allMains = params.main.split "|"
            @mainParams = params
            # atom.notifications.addSuccess "handleSave() params.main: #{JSON.stringify params}",
            #   dismissable: true
            @processNextMain @allMains
          else
            @compileLess params

  processNextMain: (thisAllMains) ->
    @params = {}
    @allMains = thisAllMains
    # atom.notifications.addSuccess "processNextMain() #{@allMains}",
    #   dismissable: true
    @thisMain = @allMains.pop()
    # atom.notifications.addSuccess "processNextMain() #{@thisMain}, #{@allMains}",
    #   dismissable: true
    @thisMainPath = path.resolve(path.dirname(@mainParams.file), @thisMain)
    atom.notifications.addSuccess "processNextMain() #{@thisMainPath}, #{@allMains}",
      dismissable: true
    @getParams @thisMainPath, (params) =>
      params.allMains = @allMains
      # atom.notifications.addSuccess "processNextMain() getParams() #{JSON.stringify params}",
      #   dismissable: true
      @compileLess params

  writeFiles: (output, newPath, newFile, params) ->
    atom.notifications.addSuccess "writeFiles() newPath #{newPath}",
      dismissable: true
    async.series
      css: (callback) =>
        if output.css
          @writeFile output.css, newPath, newFile, params, ->
            callback null, newFile
        else
          callback null, null
      map: (callback) =>
        if output.map
          newFile = "#{newFile}.map"

          @writeFile output.map, newPath, newFile, params, ->
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
            dismissable: true
          atom.notifications.addSuccess "writeFiles() params.allMains #{params.allMains}",
            dismissable: true
          if params.allMains.length > 0
            @processNextMain params.allMains
        else
          atom.notifications.addSuccess "File created",
            detail: results.css
            dismissable: true


  writeFile: (contentFile, newPath, newFile, params, callback) ->
    mkdirp newPath, (err) ->
      if err
        atom.notifications.addError err,
          dismissable: true
      else
        fs.writeFile newFile, contentFile, params, callback

  compileLess: (params) ->
    return if !params.out

    firstLine = true
    contentFile = []
    optionsLess =
      paths: [path.dirname path.resolve(params.file)]
      filename: path.basename params.file
      compress: if params.compress == 'true' then true else false
      sourceMap: if params.sourcemap == 'true' then {} else false

    atom.notifications.addSuccess "compileLess() #{JSON.stringify params} #{JSON.stringify optionsLess}",
      dismissable: true

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

        @writeFiles output, newPath, newFile, params
    , (err) ->
      if err
        atom.notifications.addError err.message,
          detail: "#{err.filename}:#{err.line}"
          dismissable: true

  getParams: (filePath, callback) ->
    atom.notifications.addError "getParams() start filePath #{filePath}",
      dismissable: true
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
      atom.notifications.addError "getParams() close #{JSON.stringify @params}",
        dismissable: true
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
