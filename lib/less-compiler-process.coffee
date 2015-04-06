module.exports =
class LessCompilerProcess
  initialize: ->
    @inProgress = false

    atom.commands.add 'atom-workspace', 'core:save': (e) =>
      if !@inProgress
        @compile atom.workspace.getActiveTextEditor()

  # Tear down any state and detach
  destroy: ->
    @detach()

  compile: (editor) ->
    path = require 'path'

    if editor?
      filePath = editor.getURI()
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
        params.main.split('|').forEach (item) =>
          @getParams path.resolve(path.dirname(filePath), item), callback
      else
        callback params

    if !fs.existsSync filePath
      atom.notifications.addError "Less-Compiler",
        detail: "main: #{filePath} not exist"
        dismissable: true

      @inProgress = false
      return null

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

  compileLess: (filePath) ->
    fs = require 'fs'
    less = require 'less'
    path = require 'path'

    compile = (params) =>
      if params.out is false
        return

      @inProgress = true

      parser = new less.Parser
        paths: [path.dirname path.resolve(params.file)]
        filename: path.basename params.file

      fs.readFile params.file, (error, data) =>
        parser.parse data.toString(), (error, tree) =>
          try
            if error
              @inProgress = false
              atom.notifications.addError "Less-Compiler",
                detail: "#{error.message} - index: #{error.index}, line: #{error.line}, file: #{error.filename}",
                dismissable: true
            else
              css = tree.toCSS
                compress: params.compress

              newFile = path.resolve(path.dirname(params.file), params.out)
              newPath = path.dirname newFile

              @writeFile css, newFile, newPath, =>
                @inProgress = false
                atom.notifications.addSuccess "Less-Compiler",
                  detail: "out: #{newFile}"
          catch e
            @inProgress = false
            atom.notifications.addError "Less-Compiler",
              detail: "#{e.message} - index: #{e.index}, line: #{e.line}, file: #{e.filename}"
              dismissable: true

    @getParams filePath, (params) ->
      if params isnt null
        compile params
