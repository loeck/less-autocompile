module.exports =
    (params, optionsLess) =>
        optionsLess.plugins = []

        if params.autoprefix
            addAutoprefix params.autoprefix, optionsLess
        if params.cleancss
            addCleanCss params.cleancss, optionsLess

addAutoprefix = (options, optionsLess) =>
    AutoprefixLessPlugin = require 'less-plugin-autoprefix'

    autoprefixOptions = {}
    if typeof options == 'string'
        autoprefixOptions.browsers = options.split ';'

    optionsLess.plugins.push new AutoprefixLessPlugin autoprefixOptions

addCleanCss = (options, optionsLess) =>
    CleanCssLessPlugin = require 'less-plugin-clean-css'

    cleancssOptions = {}
    if typeof options == 'string'
        cleancssOptions.compatibility = options

    optionsLess.plugins.push new CleanCssLessPlugin cleancssOptions
