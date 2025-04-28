module.exports =
  pkg:
    name: "@makeform/choicegrid", extend: name: '@makeform/common'
    i18n:
      en:
        "empty": "(empty)"
        "other": "Other"
        "fill-other": "Please fill"
      "zh-TW":
        "empty": "(未填寫)"
        "other": "其它"
        "fill-other": "請填寫"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, pubsub, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  pubsub.on \init.choice, (o) -> lc.defcfg = o
  init: ->
    i18n.on \languageChanged, ~> _render-option!
    getv = (t) -> if typeof(t) == \object => t.value else t
    # return value as a list regardless of original type
    # ( doesn't include other.text )
    normv = ({entry}) ->
      list = ((lc.value or {})[entry] or {}).list or []
      list.filter(->it)
    getlabel = (s) ->
      if s == \__other__ => t(\other)
      else if typeof(s) == \object => t(s.label) else t(s)
    tolabel = (s) ->
      r = (lc.values).filter(-> getv(it) == s).0
      r = if r and r.label => r.label else r
      return if r => t(r) else if typeof(s) == \string => t(s) else s
    inside = (v) ~> v in (lc.values or []).map(-> getv it)
    _render-option = debounce 100, ~> if @mod.child.option-view => @mod.child.option-view.render!
    remeta = ~>
      if !lc.defcfg => cfg = @mod.info.config or {}
      else
        cfg = {} <<< (lc.defcfg.config or {})
        for k,v of @mod.info.config => if !cfg[k]? => cfg[k] = v
      lc.meta = @mod.info.meta
      lc.cfg = cfg
      lc.other = cfg.{}other
      lc.values = cfg.values or []
      lc.entries = cfg.entries or []
      if @mod.child.view => @mod.child.view.render!
      _render-option!
    remeta!
    @on \meta, ~> remeta!
    @on \change, (v) ~>
      lc.value = (v or {})
      for k,v of lc.value => v.list = v.[]list.filter -> inside(it)
      @mod.child.view.render <[content]>
      _render-option!
    handler = ({entry, value}) ~>
      lc.{}value{}[entry].list = [value]
      @value lc.value

    @mod.child.view = view = new ldview do
      root: root
      text: content: ({node}) ~>
        if @is-empty! => return t(\empty)
        ret = @value!
        other = (ret or {}).other
        ret = if typeof(ret) == \string => [ret] else (ret.list or [])
        other-text = ''
        if ('__other__' in ret) and lc.other.enabled =>
          other-text = t("other")
          if lc.other.editable and (other or {}).text =>
            other-text += (":" + other.text)
        ret = ret
          .filter (v) -> v != \__other__
          .map (v) -> tolabel(v)
        if lc.other.enabled and other-text => ret.push other-text
        ret = ret.join(if lc.cfg.sep => that else ', ')
        if !ret => ret = t("empty")
        return ret
      handler:
        head: ({node}) -> node.style.gridColumn = "span #{lc.values.length + 1}"
        option:
          list: -> lc.values
          key: -> getv(it)
          view:
            handler:
              label: ({node, ctx}) -> node.textContent = getlabel(ctx)
        entry:
          list: -> lc.entries
          key: -> getv(it)
          view:
            handler:
              "@": ({node}) -> node.style.gridColumn = "span #{lc.values.length + 1}"
              label: ({node, ctx}) -> node.textContent = getlabel(ctx)
              option:
                list: ~> lc.values
                key: -> getv(it)
                view:
                  action: click: "@": ({node, ctx, ctxs}) ~>
                    handler {entry: getv(ctxs.0), value: getv(ctx)}
                  handler:
                    "check": ({node, ctx, ctxs}) ->
                      node.classList.toggle \active, (getv(ctx) in normv({entry: getv(ctxs.0)}))

        input: ({node}) ~>
          #vals = normv!
          #for n in (node.options or []) => n.selected = n.value in vals
          #node.classList.toggle \is-invalid, @status! == 2

  render: -> @mod.child.view.render!
  validate: ->
    Promise.resolve!then ~>
      if !((@mod.info.config or {}).other or {}).require-on-check => return
      v = @value!
      if v and (v.other or {}).enabled and !(v.other or {}).text =>
        return ["other-error"]
      return

