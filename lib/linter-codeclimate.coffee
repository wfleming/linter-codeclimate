{CompositeDisposable} = require 'atom'
Path = require 'path'

module.exports =
  config:
    executablePath:
      type: 'string'
      default: '/usr/local/bin/codeclimate'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-codeclimate.executablePath',
      (executablePath) =>
        @executablePath = executablePath

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    Helpers = require('atom-linter')
    configurationFile = '.codeclimate.yml'
    linterMap = {
      'Ruby': 'rubocop'
    }
    provider =
      grammarScopes: ['*'] # Lint everything then filter with map
      scope: 'project'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        fileDir = Path.dirname(filePath)
        grammarName = textEditor.getGrammar().name
        linterName = null

        if (linterMap.hasOwnProperty(grammarName) == true)
          linterName = linterMap[grammarName]
        else
          return []

        configurationFilePath = Helpers.findFile(fileDir, configurationFile)
        if (!configurationFilePath)
          fileDir = __dirname

        execPath = Path.dirname(configurationFilePath)
        relativeFilePath = atom.project.relativize(filePath)

        cmd = "codeclimate analyze -f json -e " + linterName + " " + relativeFilePath + " < /dev/null"

        return Helpers
          .exec("/bin/bash", ["-c", cmd], {cwd: execPath})
          .then(JSON.parse)
          .then((messages) =>
            linterResults = []
            for issue in messages
              do (issue) ->
                beginLine = issue.location.positions.begin.line
                endLine = issue.location.positions.end.line
                lintData = {
                  type: issue.check_name,
                  text: issue.description,
                  filePath: issue.location.path,
                  range: [[beginLine-1,0], [endLine-1,0]]
                }
                linterResults.push lintData
            console.log "Logged " + messages.length
            return linterResults
          )