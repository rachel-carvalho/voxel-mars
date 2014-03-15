parse = ->
  params = {}

  for param in window.location.hash.substring(1).split('&')
    if param
      parts = param.split '='
      params[parts[0]] = parts.splice(1).join '='

  params

module.exports = {parse}