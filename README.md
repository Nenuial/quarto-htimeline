# Horizontal Timeline Extension For Quarto

A filter extension that turns a list of headings into a horizontal timeline on
Reveal.js slides. Dates sit above the line, titles below it, and a full-width
box with the details of the current event appears under the timeline as you
step through the slide.

## Installing

```bash
quarto add Nenuial/quarto-htimeline
```

This will install the extension under the `_extensions` subdirectory.

## Using

Add in your YAML frontmatter:

```yaml
filters:
  - htimeline
```

Then write a timeline as a `.htimeline` div. Each heading is an event, and
everything under a heading is the content of its box:

```markdown
## The Middle Ages

::: {.htimeline}

### Fall of Constantinople {date="1453-05-29"}

Any markdown: lists, callouts, executed code, figures…

![](images/map.png){.lightbox}

### Storming of the Bastille {date="1789-07-14"}

The box can also stay short.

:::
```

- Events are the highest-level headings inside the div; deeper headings stay
  inside the boxes.
- Titles accept inline markdown (italics, superscripts…) and wrap within
  their column.
- When a box ends with a lone image, the image is placed in a column on the
  right of the text.
- Fragments inside a box (e.g. an incremental list) run in order before the
  next event.

### Dates

| `date=`                  | Displayed                          |
|--------------------------|------------------------------------|
| `1054`                   | **1054**                           |
| `1917-02`                | February / **1917**                |
| `1989-11-09`             | November 9 / **1989**              |
| `1533--1584`             | **1533–1584**                      |
| `1962-10-16--1962-10-28` | October 16–28 / **1962**           |
| `2000--`                 | **2000–**                          |
| anything else            | rendered as markdown, e.g. `IX^e^ siècle` |

The year is shown in bold next to the line, the day and month above it in a
lighter style. `date-detail="…"` replaces that upper line. Month names follow
the document `lang` (French, English, German and Italian are built in).

### Options

On the timeline div:

| Option                | Effect                                                         |
|-----------------------|----------------------------------------------------------------|
| `.show-all`           | All dates and titles visible from the start (dimmed)           |
| `.static`             | No steps; everything is shown at once                          |
| `.first-visible`      | The first event is shown when the slide opens                  |
| `rows="2"`            | Spread the events over several rows; the line snakes down, turning at the slide edges |
| `box="side"`          | Boxes in a panel to the right of the timeline (default when `rows` > 1); each box is centred on its row, with an arrow pointing at it, and pushed up or down to stay on the slide |
| `box="below"`         | Boxes under the timeline (default with a single row)          |
| `side-width="50%"`    | Width of the side panel (default `55%`)                        |
| `aside-width="25%"`   | Width of the image column (default `20%`); `none` disables it  |

On a heading: `aside-width="…"` for that event only, and `.smaller` for a
smaller font in its box.

### Styling

Colors come from the Reveal theme (`$body-color`, `$link-color`, `$body-bg`),
so the timeline adapts to any theme. To tune it, override these variables in
your theme or a CSS file:

```css
.htimeline {
  --htl-accent: #c0392b;      /* current event, box border */
  --htl-ink: #333;            /* axis, markers, text */
  --htl-bg: #fff;             /* inside of the markers */
  --htl-font-size: 0.78em;    /* whole timeline */
  --htl-box-font-size: 1em;   /* boxes, relative to the timeline */
  --htl-row-gap: 1.8em;       /* space between rows when rows > 1 */
}
```

The current-event highlight relies on the CSS `:has()` selector, supported by
all current browsers. Placing the side-panel boxes next to their row uses a
small script; without it (e.g. in a PDF export) they sit at the top of the
panel.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

## License

MIT licensed.
