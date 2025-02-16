# Week Calendar

Print a large calendar of each week for a number of years. Sometimes this sort
of thing is called a Memento Mori calendar or life calendar. I wanted a calendar
with boxes big enough to write in.

[Example](example-calendar.pdf) of a 36x24 inch calendar starting in the year 2000 for 50 years.

There are a few settings you can adjust in the Lua code:

```lua
  local print_dates = true -- should dates be printed in every square?
  local year_one_line = false -- should the year in the left column be on one line?
  local paper_width = 48 -- in inches: keep in sync with the geometry command above
  local paper_height = 36 -- in inches: keep in sync with the geometry command above
  local margin = 1 -- in inches: keep in sync with the geometry command above

  local start = 2000 -- year of first row
  local years = 50 -- how many years
```

If you change the vertical size of the calendar, you'll need to adjust the box
height manually. You can uncomment the `showframe` option to the geometry
package to better see how much vertical space you have while making this
adjustment.

```lua
  local box_height = .293
```

Since a year is actually a little more than 52 weeks, you'll notice that some years are missing a 53rd week. Feel free to enjoy the extra "leap week" not on the calendar.
