module.exports =
  pkg:
    name: "@makeform/choicegrid", extend: name: '@makeform/common'
    i18n:
      en:
        "new entry": "New Entry"
        "new option": "New Option"
        "empty": "(empty)"
        config:
          values: name: 'Options', desc: "List of column options for the grid"
          entries: name: 'Entries', desc: "List of row entries for the grid"
          sep: name: 'Separator', desc: "Separator for displaying multiple selected values"
      "zh-TW":
        "new entry": "新題目"
        "new option": "新選項"
        "empty": "(未填寫)"
        config:
          values: name: '選項', desc: "網格的欄位選項列表"
          entries: name: '條目', desc: "網格的列條目列表"
          sep: name: '分隔符號', desc: "顯示多個選中值時的分隔符號"
  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt
mod = ({root, ctx, data, pubsub, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  hitf = ~> @hitf
  keygen = -> "_#{Date.now!}#{Math.random!toString(36)substring(2)}"
  @client = ->
    minibar: []
    meta: config:
      values: type: \list, name: \config.values.name, desc: \config.values.desc
      entries: type: \list, name: \config.entries.name, desc: \config.entries.desc
      sep: type: \text, name: \config.sep.name, desc: \config.sep.desc
    render: ~> lc.view.render!
    sample: ~>
      config:
        values: [
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 1'
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 2'
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 3'
        ]
        entries: [
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Entry 1'
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Entry 2'
          * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Entry 3'
        ]
  init: ->
    i18n.on \languageChanged, ~> _render-option!
    getv = (t) ->
      if typeof(t) == \string => t
      else (t?key or t?value or hitf!totext(t?label))
    # return value as a list regardless of original type
    normv = ({entry}) ->
      list = ((lc.value or {})[entry] or {}).list or []
      list.filter(->it)
    inside = (v) ~> v in (lc.values or []).map(-> getv it)
    _render-option = debounce 100, ~> if @mod.child.option-view => @mod.child.option-view.render!
    remeta = ~>
      cfg = @mod.info.config or {}
      lc.meta = @mod.info.meta
      lc.cfg = cfg
      lc.values = cfg.values or []
      lc.entries = cfg.entries or []
      if @mod.child.view => @mod.child.view.render!
      _render-option!
    remeta!
    @on \meta, ~> remeta!
    @on \change, (v) ~>
      lc.value = (v or {})
      for k,v of lc.value => v.list = v.[]list.filter -> inside(it)
      @mod.child.view.render <[content entry]>
      _render-option!
    handler = ({entry, value}) ~>
      lc.{}value{}[entry].list = [value]
      lc.value.raw = value-to-text!
      @value lc.value

    option-to-label = (o) ->
      vals = hitf!get!?config?values or []
      o = getv o
      v = vals.filter((v) -> getv(v) == o).0
      hitf!totext(if typeof(v) == \string => v else v?value or v?label)
    ent-to-label = (e) ->
      vals = hitf!get!?config?entries or []
      e = getv e
      v = vals.filter((v) -> getv(v) == e).0
      hitf!totext(if typeof(v) == \string => v else v?value or v?label)
    value-to-text = ->
      (hitf!get!?config?entries or [])
        .map (ent) ->
          key = ent-to-label ent
          val = (lc.value?[getv ent]?list or [])
            .map (v) -> option-to-label v
            .join(lc.cfg.sep)
          "#key: #val"
        .join \\n

    @mod.child.view = view = lc.view = new ldview do
      root: root
      text: content: ({node}) ~>
        if @is-empty! => return t(\empty)
        ret = @value!
        ret = value-to-text!
        if !ret => ret = t("empty")
        ret
      action:
        click:
          "add-option": ({node, views}) ~>
            new-option =
              key: keygen!
              label: hitf!wrap "#{i18n.language}": "untitled"
            hitf!get!{}config[]values.push new-option
            hitf!set!
            views.0.render!
          "add-entry": ({node, views}) ~>
            new-entry =
              key: keygen!
              label: hitf!wrap "#{i18n.language}": "untitled"
            hitf!get!{}config[]entries.push new-entry
            hitf!set!
            views.0.render!
      handler:
        grid: ({node}) ->
          v = hitf!get!config?values or []
          v = if Array.isArray(v) => v else if v => [v] else []
          cols = v.length + 1
          node.style.gridTemplateColumns = "repeat(#{cols}, minmax(8em, 1fr))"
        head: ({node}) ->
          v = hitf!get!config?values or []
          v = if Array.isArray(v) => v else if v => [v] else []
          node.style.gridColumn = "span #{v.length + 1}"
        option:
          list: ~>
            v = hitf!get!config?values or []
            if Array.isArray(v) => v else if v => [v] else []
          key: -> getv(it)
          view:
            action: click:
              "@": ({node, evt}) ->
                if !(node.parentNode and (n = ld$.find(node.parentNode,'[ld=editor]',0))) => return
                evt.stopPropagation!
                evt.preventDefault!
              "remove-option": ({node, ctx, views}) ~>
                cfg = hitf!get!{}config
                cfg.values = cfg.[]values.filter -> getv(it) != getv(ctx)
                hitf!set!
                views.0.render!
              label: hitf!edit {obj: ({ctx}) -> ctx.{}label}
            handler:
              label: hitf!render obj: ({ctx}) -> ctx.label or ctx
        entry:
          list: ~>
            v = hitf!get!config?entries or []
            if Array.isArray(v) => v else if v => [v] else []
          key: -> getv(it)
          view:
            action: click:
              "@": ({node, evt}) ->
                if !(node.parentNode and (n = ld$.find(node.parentNode,'[ld=editor]',0))) => return
                evt.stopPropagation!
                evt.preventDefault!
              "remove-entry": ({node, ctx, views}) ~>
                cfg = hitf!get!{}config
                cfg.entries = cfg.[]entries.filter -> getv(it) != getv(ctx)
                hitf!set!
                views.0.render!
              label: hitf!edit {obj: ({ctx}) -> ctx.{}label}
            handler:
              "@": ({node}) ->
                v = hitf!get!config?values or []
                v = if Array.isArray(v) => v else if v => [v] else []
                node.style.gridColumn = "span #{v.length + 1}"
              label: hitf!render obj: ({ctx}) -> ctx.label or ctx
              option:
                list: ~> lc.values
                key: -> getv(it)
                view:
                  action: click: "@": ({node, ctx, ctxs}) ~>
                    handler {entry: getv(ctxs.0), value: getv(ctx)}
                  handler:
                    "check": ({node, ctx, ctxs}) ->
                      node.classList.toggle \active, (getv(ctx) in normv({entry: getv(ctxs.0)}))
  render: -> @mod.child.view.render!
