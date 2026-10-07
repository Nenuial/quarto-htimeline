--[[
htimeline – horizontal timeline for Reveal.js slides

  ::: {.htimeline}

  ### Le Grand Schisme {date="1054-07-16"}

  Any markdown: the content of the box shown under the line
  while this event is the current step.

  ![](images/icone.png)   <- a lone image at the end goes into a side column

  ### Next event {date="1236--1480"}

  :::

Dates (attribute `date`):
  1054                 -> 1054
  1917-02              -> février / 1917
  1989-11-09           -> 9 novembre / 1989
  1533--1584           -> 1533–1584
  1917-02--1917-10     -> février – octobre / 1917
  2000--               -> 2000–
  anything else        -> rendered as markdown (e.g. "IX^e^ siècle")
  `date-detail="…"` overrides the small upper line.

Options on the timeline div:
  .show-all       all dates/titles visible from the start (dimmed), steps highlight
  .static         no steps at all
  .first-visible  first event shown on slide entry
  aside-width="25%"  width of the side image column (also per heading);
                     aside-width="none" disables the side column
]]

local MONTHS = {
  fr = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet",
         "août", "septembre", "octobre", "novembre", "décembre" },
  en = { "January", "February", "March", "April", "May", "June", "July",
         "August", "September", "October", "November", "December" },
  de = { "Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
         "August", "September", "Oktober", "November", "Dezember" },
  it = { "gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
         "agosto", "settembre", "ottobre", "novembre", "dicembre" },
}

local lang = "fr"
local css_added = false

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function md_inlines(s)
  local doc = pandoc.read(s, "markdown")
  if #doc.blocks == 0 then
    return pandoc.Inlines({})
  end
  return pandoc.utils.blocks_to_inlines(doc.blocks)
end

-- "1917", "1917-02", "1917-02-23" -> { y, m, d }
local function parse_point(s)
  local y, m, d = s:match("^(%d+)%-(%d%d?)%-(%d%d?)$")
  if not y then
    y, m = s:match("^(%d+)%-(%d%d?)$")
  end
  if not y then
    y = s:match("^(%d+)$")
  end
  if not y then
    return nil
  end
  return { y = y, m = tonumber(m), d = tonumber(d) }
end

local function day_month(p)
  if not p.m or p.m < 1 or p.m > 12 then
    return nil
  end
  local month = (MONTHS[lang] or MONTHS.en)[p.m]
  if not p.d then
    return month
  end
  if lang == "fr" then
    return (p.d == 1 and "1er" or tostring(p.d)) .. " " .. month
  elseif lang == "de" then
    return p.d .. ". " .. month
  elseif lang == "en" then
    return month .. " " .. p.d
  end
  return p.d .. " " .. month
end

-- Returns main (year line) and detail (upper line) as strings,
-- or nil when the date is not ISO-like.
local function parse_date(s)
  s = trim(s):gsub("–", "--")
  local a, b = s:match("^(.-)%s*%-%-%s*(.*)$")
  if not a then
    local p = parse_point(s)
    if p then
      return p.y, day_month(p)
    end
    return nil
  end

  local pa = parse_point(a)
  local pb = (b == "") and {} or parse_point(b)
  if not pa or not pb then
    return nil
  end
  local da = day_month(pa)
  if not pb.y then
    return pa.y .. "–", da
  end
  local db = day_month(pb)
  if pa.y == pb.y and pa.m and pa.m == pb.m and pa.d and pb.d then
    -- same month: "16–28 octobre"
    local month = (MONTHS[lang] or MONTHS.en)[pa.m]
    if lang == "de" then
      return pa.y, pa.d .. ".–" .. pb.d .. ". " .. month
    elseif lang == "en" then
      return pa.y, month .. " " .. pa.d .. "–" .. pb.d
    end
    return pa.y, pa.d .. "–" .. pb.d .. " " .. month
  end
  if pa.y == pb.y then
    local detail = (da and db) and (da .. " – " .. db) or da or db
    return pa.y, detail
  end
  return pa.y .. "–" .. pb.y, (da and db) and (da .. " – " .. db) or nil
end

local function make_date(attrs)
  local src = attrs["date"] or ""
  local main, detail = parse_date(src)
  main = main and pandoc.Inlines(main) or md_inlines(src)
  if attrs["date-detail"] then
    detail = md_inlines(attrs["date-detail"])
  elseif detail then
    detail = pandoc.Inlines(detail)
  end

  local blocks = pandoc.Blocks({})
  if detail then
    blocks:insert(pandoc.Div(pandoc.Plain(detail), pandoc.Attr("", { "htl-date-detail" })))
  end
  blocks:insert(pandoc.Div(pandoc.Plain(main), pandoc.Attr("", { "htl-date-main" })))
  return pandoc.Div(blocks, pandoc.Attr("", { "htl-date" }))
end

local function is_lone_image(b)
  if b.t == "Figure" then
    return true
  end
  return (b.t == "Para" or b.t == "Plain") and #b.content == 1 and b.content[1].t == "Image"
end

local function make_box(body, aside_width)
  local last = body[#body]
  if aside_width == "none" or #body < 2 or not is_lone_image(last) then
    return pandoc.Div(body, pandoc.Attr("", { "htl-box" }))
  end

  local main = body:clone()
  main:remove(#main)
  local aside_classes = { "htl-aside" }
  last:walk({
    Image = function(img)
      if img.classes:includes("no-caption") then
        table.insert(aside_classes, "no-caption")
      end
    end,
  })
  return pandoc.Div({
    pandoc.Div(main, pandoc.Attr("", { "htl-main" })),
    pandoc.Div({ last }, pandoc.Attr("", aside_classes)),
  }, pandoc.Attr("", { "htl-box", "has-aside" }, { style = "--htl-aside-width:" .. aside_width }))
end

local function make_event(i, heading, body, step, defaults)
  local classes = { "htl-event" }
  if step then
    table.insert(classes, "fragment")
  end
  for _, c in ipairs(heading.classes) do
    table.insert(classes, c)
  end

  local children = pandoc.Blocks({
    make_date(heading.attributes),
    pandoc.Div({}, pandoc.Attr("", { "htl-marker" })),
    pandoc.Div(pandoc.Plain(heading.content), pandoc.Attr("", { "htl-title" })),
  })
  if #body > 0 then
    local aside_width = heading.attributes["aside-width"] or defaults["aside-width"] or "20%"
    children:insert(make_box(body, aside_width))
  end
  return pandoc.Div(children, pandoc.Attr("", classes, { style = "--i:" .. i }))
end

local function add_css()
  if css_added or not quarto.doc.is_format("html:js") then
    return
  end
  quarto.doc.add_html_dependency({
    name = "htimeline",
    version = "0.1.0",
    stylesheets = { "htimeline.css" },
  })
  css_added = true
end

local function timeline(div)
  if not div.classes:includes("htimeline") then
    return nil
  end

  -- Events are the headings of the highest level found in the div;
  -- deeper headings stay inside the boxes.
  local level
  for _, b in ipairs(div.content) do
    if b.t == "Header" and (not level or b.level < level) then
      level = b.level
    end
  end
  if not level then
    return nil
  end

  local intro, events, current = pandoc.Blocks({}), {}, nil
  for _, b in ipairs(div.content) do
    if b.t == "Header" and b.level == level then
      current = { heading = b, body = pandoc.Blocks({}) }
      table.insert(events, current)
    elseif current then
      current.body:insert(b)
    else
      intro:insert(b)
    end
  end

  local static = div.classes:includes("static")
  local first_visible = div.classes:includes("first-visible")
  local defaults = { ["aside-width"] = div.attributes["aside-width"] }
  div.attributes["aside-width"] = nil

  local content = pandoc.Blocks({ pandoc.Div({}, pandoc.Attr("", { "htl-axis" })) })
  for i, ev in ipairs(events) do
    local step = not static and not (first_visible and i == 1)
    content:insert(make_event(i, ev.heading, ev.body, step, defaults))
  end
  div.content = content

  local style = div.attributes["style"]
  div.attributes["style"] = "--n:" .. #events .. (style and ("; " .. style) or "")

  add_css()

  if #intro > 0 then
    intro:insert(div)
    return intro
  end
  return div
end

return {
  {
    Meta = function(meta)
      if meta.lang then
        local l = pandoc.utils.stringify(meta.lang):lower():match("^(%a+)")
        if l then
          lang = l
        end
      end
    end,
  },
  { Div = timeline },
}
