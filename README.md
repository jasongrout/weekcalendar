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
  month_labels = false,    -- true: month names across the top; false: week numbers
  date_font = [[\footnotesize\bfseries\datefont]],   -- font for dates in each box
  label_font = [[\Huge\bfseries\headingfont]],       -- font for year and header labels
}
```

With `month_labels = true`, the header shows month names instead of week
numbers, with each name centered over the weeks that make up that month. The
positions are approximate: a month's middle day of year, converted to weeks.
Actual ISO week boundaries shift by a day or two from year to year, so a
single header row can only ever be roughly aligned for all rows.

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

## Day Calendar

Generate a letter-size calendar with one row per week and a column for each day
of the week (Monday first). Day numbers are printed in each cell, with the
month abbreviation shown on month boundaries, and the year (or year range) as a
title at the top.

```
lualatex daycalendar.tex
```

### Configuration

Edit the `cfg` table at the top of `daycalendar.tex`:

```lua
cfg = {
  paper_width = 8.5,         -- inches
  paper_height = 11,         -- inches
  margin = .5,               -- inches
  print_dates = true,        -- print day numbers in every square
  num_rows = 15,             -- weeks (rows) to show

  -- Starting Monday of the first row (rolls back to Monday if not one)
  start_year = 2026,
  start_month = 5,
  start_day = 18,
}
```

## Grid Library Options

The calendars use `gridlib.lua`, which provides two grid drawing functions (`draw_grid` with gaps between cells, and `draw_grid_rowbox` with each row as one box and dotted internal dividers). Both accept these options:

| Option | Default | Description |
|--------|---------|-------------|
| `label_font` | `\Huge\bfseries` | Font for row and column labels |
| `left_margin` | 1.0 | Width in inches for left label column |
| `header_height` | 0.4 | Height in inches for top label row |
| `gap` | 0.06 | Gap between rows in inches |
| `line_width` | 1.2 | Box border thickness in points |
| `divider_style` | `dotted` | TikZ style for internal column dividers |
| `cell_content` | nil | Function `(row, col)` returning TeX string for cell content |
| `top_positioned_labels` | nil | Array of `{pos, text}` drawn along the top instead of the per-column labels; `pos` is in fractional column units from the left edge of column 1 |
| `row_separator_interval` | 0 | Draw heavy line every N rows (0 to disable) |
| `row_separator_start` | 0 | Row index where first separator appears (both calendars auto-calculate this to align with years divisible by 5) |
| `row_separator_width` | line_width | Line width for separators in points |

## Tips

- Uncomment `showframe` in the geometry package options to visualize margins while adjusting layout.
- After generating, use the printed `pdfcrop` command to extract an 8.5x11 test section for printing before committing to a large format print.


# Font selection

The week calendar's `date_font` and `label_font` use the `\datefont` and
`\headingfont` families defined at the top of `weekcalendar.tex` — uncomment a
different `\newfontfamily` line there to try another pairing.

For small sizes, it is helpful to select a font that:

1. Has consistent baseline for numbers for a clean look (no old-style numbers)
2. Has an open 6 (so not Inter, for example) - otherwise the 6 looks too much like an 8.
3. Has a large x-height

Some of the best free fonts for small text I've found are:

- Bitstream Charter (or XCharter)
- Avenir Next
- IBM Plex Sans

Apparently some commercial fonts good for very small sizes:

- [Retina MicroPlus](https://frerejones.com/families/retina)
- [Bell Centennial](https://fonts.adobe.com/fonts/bell-centennial-std) (see [history](https://ananthpai.com/bell-centennial/))
