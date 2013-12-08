@json = (obj, opts) ->
  json_obj = null

  if except = opts?.except?.split ' '
    json_obj = {}
    for key, value of obj
      unless key in except
        json_obj[key] = value
  
  JSON.stringify json_obj || obj