# Calendar

Print a large calendar of each month or ISO 8601 week for a number of years.
Sometimes this sort of thing is called a Memento Mori calendar or life calendar.
I wanted a calendar with boxes big enough to write in.

This repo is also largely an experiment in coding with Claude Code.

## Requirements

Install [TeX Live](https://tug.org/texlive/) with LuaLaTeX support.

## Week Calendar

Generate a calendar with one row per year, showing 52 weeks as columns with date ranges in each cell.

Since a year is actually a little more than 52 seven-day weeks, some years have
a 53rd ISO 8601 week that is not printed on the calendar. A year has a 53rd week
when the last day of week 52 is Dec 26 or Dec 27. Enjoy the extra week not on
the calendar every few years.


```
lualatex weekcalendar.tex
```

### Configuration

Edit the `cfg` table at the top of `weekcalendar.tex`:

```lua
cfg = {
  paper_width = 60,        -- inches
  paper_height = 36,       -- inches
  margin = .8,             -- inches
  print_dates = true,      -- show date ranges in every square
  start = 2025,            -- year of first row
  years = 25,              -- how many years (rows)
  date_font = [[\small\bfseries]],  -- font for dates in each box
}
```

## Month Calendar

Generate a simpler grid with one row per year and 12 columns for months.

```
lualatex monthcalendar.tex
```

### Configuration

Edit the `cfg` table at the top of `monthcalendar.tex`:

```lua
cfg = {
  paper_width = 24,        -- inches
  paper_height = 36,       -- inches
  margin = 0.8,            -- inches
  start_year = 2004,       -- first year row
  num_years = 21,          -- how many years (rows)
}
```

## Grid Library Options

Both calendars use `gridlib.lua` which provides two grid drawing functions. The `draw_grid_rowbox` function (used by both) accepts these options:

| Option | Default | Description |
|--------|---------|-------------|
| `label_font` | `\Huge\bfseries` | Font for row and column labels |
| `left_margin` | 1.0 | Width in inches for left label column |
| `header_height` | 0.4 | Height in inches for top label row |
| `gap` | 0.06 | Gap between rows in inches |
| `line_width` | 1.2 | Box border thickness in points |
| `divider_style` | `dotted` | TikZ style for internal column dividers |
| `cell_content` | nil | Function `(row, col)` returning TeX string for cell content |
| `row_separator_interval` | 0 | Draw heavy line every N rows (0 to disable) |
| `row_separator_start` | 1 | Row to start counting from for separators |
| `row_separator_width` | line_width | Line width for separators in points |

## Tips

- Uncomment `showframe` in the geometry package options to visualize margins while adjusting layout.
- After generating, use the printed `pdfcrop` command to extract an 8.5x11 test section for printing before committing to a large format print.