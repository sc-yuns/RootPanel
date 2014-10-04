path = require 'path'
fs = require 'fs'
_ = require 'underscore'

stringify = require 'json-stable-stringify'
Negotiator = require 'negotiator'

utils = require './utils'
cache = require './cache'
config = require '../config'

i18n_data = {}

for lang in config.i18n.available_language
  i18n_data[lang] = require "./locale/#{lang}"

exports.loadForPlugin = (plugin) ->
  for lang in config.i18n.available_language
    path = "../plugin/#{plugin.name}/locale/#{lang}.json"

    if fs.existsSync path
      i18n_data[lang]['plugins'][plugin.name] = require lang

exports.parseLanguageCode = parseLanguageCode = (language) ->
  [lang, country] = language.replace('-', '_').split '_'

  return {
    language: language
    lang: lang?.toLowerCase()
    country: country?.toUpperCase()
  }

exports.calcLanguagePriority = (req) ->
  negotiator = new Negotiator req

  result = []

  if req.cookies.language
    language_info = parseLanguageCode req.cookies.language

    result = _.union result, _.filter config.i18n.available_language, (i) ->
      return i.language == language_info.language

    result = _.union result, _.filter config.i18n.available_language, (i) ->
      return parseLanguageCode(i).lang == language_info.lang

  result = _.union result, _.filter config.i18n.available_language, (i) ->
    return parseLanguageCode(i).lang in negotiator.languages()

  result.push config.i18n.default_language

  result = _.union result, config.i18n.available_language

  return result

exports.translateByLanguage = (name, language) ->
  keys = name.split '.'
  keys.unshift language

  result = i18n_data

  for item in keys
    if result[item] == undefined
      return undefined
    else
      result = result[item]

  return result

exports.translate = (name, req) ->
  priority_order = exports.calcLanguagePriority req

  for language in priority_order
    result = exports.translateByLanguage name, language

    if result != undefined
      return result

  return name

exports.getTranslator = (req) ->
  return  (name, payload) ->
    result = exports.translate name, req

    if _.isObject payload
      for k, v of payload
        result = result.replace new RegExp("__#{k}__", 'g'), v

    return result

exports.pickClientLocale = (req) ->
  console.log req.cookies
  cache_key = "client.locale:#{req.cookies['language']}/#{req.headers['accept-language']}"
  cached_result = cache.counter.get cache_key

  if cached_result
    return cached_result

  priority_order = exports.calcLanguagePriority req

  result = {}

  for language in priority_order
    result = _.extend result, i18n_data[language]

  cache.counter.set cache_key, result, NaN

  return result

exports.clientLocaleHash = (req) ->
  return utils.sha256 stringify exports.pickClientLocale req

exports.downloadLocales = (req, res) ->
  if req.params['language']
    req.cookies['language'] = req.params['language']

  res.json exports.pickClientLocale req
