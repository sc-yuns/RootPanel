{pluggable} = app

module.exports = pluggable.createHelpers exports =
  name: 'supervisor'
  type: 'service'
  dependencies: ['linux']

supervisor = require './supervisor'

exports.registerHook 'view.panel.scripts',
  path: '/plugin/linux/script/panel.css'

exports.registerHook 'view.panel.widgets',
  generator: (req, callback) ->
    exports.render 'widget', req, {}, callback

exports.registerServiceHook 'disable',
  filter: (req, callback) ->
    supervisor.removePrograms req.account, callback

app.express.use '/plugin/supervisor', require './router'
