-- gridlib.lua: Shared grid drawing library for LaTeX documents

local gridlib = {}

function gridlib.pt2in(pt)
  return pt / 72.0
end

-- Draw a grid with labels along the top and left side
-- Parameters:
--   width: total width of grid area in inches (excluding left_margin)
--   height: total height of grid area in inches (excluding header)
--   top_labels: array of strings for column headers
--   left_labels: array of strings for row headers
--   options: table with optional settings:
--     top_font_size: TeX font size command (default: [[\LARGE]])
--     left_font_size: TeX font size command (default: [[\LARGE]])
--     left_margin: width in inches for left label column (default: 0.6)
--     cell_content: function(row, col) returning TeX string for cell content (default: nil)
function gridlib.draw_grid(width, height, top_labels, left_labels, options)
  options = options or {}
  local top_font = options.top_font_size or [[\LARGE]]
  local left_font = options.left_font_size or [[\LARGE]]
  local left_margin = options.left_margin or 0.6
  local cell_content = options.cell_content

  local num_cols = #top_labels
  local num_rows = #left_labels

  -- Calculate box width
  -- The 10pt accounts for \fbox borders/padding plus inter-box spacing
  local box_width = (width - left_margin)/num_cols - gridlib.pt2in(10.0)
  local header_space_width = box_width + gridlib.pt2in(6.8)

  -- Measure actual header height by running TeX locally and reading the box
  tex.runtoks(function()
    tex.sprint(string.format([[\setbox0=\hbox{%s Xg}]], top_font))
  end)
  local header_height_pt = tex.box[0].height / 65536
  local header_space = gridlib.pt2in(header_height_pt + 4)

  texio.write_nl(string.format('Measured header height: %.1fpt', header_height_pt))

  -- Calculate box_height so vertical gap equals horizontal gap
  local fbox_overhead = gridlib.pt2in(6.8) -- 2*(fboxrule + fboxsep) = 2*(0.4pt + 3pt)
  local visible_gap = gridlib.pt2in(3.2) -- small gap to match horizontal inter-box spacing
  local available = height - header_space
  -- Total = num_rows * (box_height + fbox_overhead) + (num_rows - 1) * visible_gap
  local box_height = (available - num_rows * fbox_overhead - (num_rows - 1) * visible_gap) / num_rows

  texio.write_nl(string.format('Grid dimensions - WIDTH: %.3fin, HEIGHT: %.3fin', box_width, box_height))

  -- Print top labels across the header
  local header_start = left_margin + box_width/10
  tex.print(string.format([[\noindent\kern%.5fin]], header_start))
  for i, label in ipairs(top_labels) do
    tex.print(string.format([[{\hbox to %.5fin{\hfil %s %s\hfil}}]], header_space_width, top_font, label))
  end
  tex.print([[\par\vskip2pt\noindent]])

  -- Main grid
  for row = 1, num_rows do
    -- Left label, centered vertically
    tex.print(string.format([[{\vbox to %.5fin{\vfil\hbox to %.5fin{\hfil%s %s\hfil}\vfil}}]],
      box_height, left_margin, left_font, left_labels[row]))

    -- Boxes for each column
    for col = 1, num_cols do
      local content = ""
      if cell_content then
        content = cell_content(row, col) or ""
      end
      tex.print(string.format([[\fbox{%s\vbox to %.5fin{\vfil\hbox to %.5fin{\hfil}\vfil}}]],
           content, box_height, box_width))
    end

    -- Space between each row
    if row < num_rows then
      tex.print(string.format([[\par\nointerlineskip\vskip%.5fin\noindent]], visible_gap))
    end
  end

  return {
    box_width = box_width,
    box_height = box_height
  }
end

-- Helper to generate a range of numbers as string labels
function gridlib.number_range(start, count)
  local labels = {}
  for i = 0, count - 1 do
    labels[#labels + 1] = tostring(start + i)
  end
  return labels
end

-- Month name abbreviations
gridlib.month_names = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}

return gridlib
