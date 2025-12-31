-- gridlib.lua: Shared grid drawing library for LaTeX documents

local gridlib = {}

function gridlib.pt2in(pt)
  return pt / 72.0
end

-- Convert TeX scaled points to inches
-- TeX dimensions are stored in scaled points (sp), where 1pt = 65536sp
function gridlib.sp2in(sp)
  return sp / 65536 / 72.27
end

-- Read page dimensions from TeX (set by geometry package)
-- Returns paper_width, paper_height, text_width, text_height in inches
function gridlib.get_page_dimensions()
  local paper_width = gridlib.sp2in(tex.dimen.paperwidth)
  local paper_height = gridlib.sp2in(tex.dimen.paperheight)
  local text_width = gridlib.sp2in(tex.dimen.textwidth)
  local text_height = gridlib.sp2in(tex.dimen.textheight)
  return paper_width, paper_height, text_width, text_height
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
  -- header_space includes: header height, plus spacing for \par\vskip2pt and depth buffer
  local header_space = gridlib.pt2in(header_height_pt + 10)

  texio.write_nl(string.format('Measured header height: %.1fpt', header_height_pt))

  -- Calculate box_height so vertical gap equals horizontal gap
  local fbox_overhead = gridlib.pt2in(6.8) -- 2*(fboxrule + fboxsep) = 2*(0.4pt + 3pt)
  local visible_gap = gridlib.pt2in(3.2) -- small gap to match horizontal inter-box spacing
  local available = height - header_space
  -- Total = num_rows * (box_height + fbox_overhead) + (num_rows - 1) * visible_gap
  local box_height = (available - num_rows * fbox_overhead - (num_rows - 1) * visible_gap) / num_rows

  texio.write_nl(string.format('Grid dimensions - WIDTH: %.3fin, HEIGHT: %.3fin', box_width, box_height))

  -- Print top labels across the header
  -- Each fbox takes exactly: box_width + fbox_overhead (no inter-box gap since they're adjacent)
  local cell_pitch = box_width + fbox_overhead
  -- Header starts after left_margin, plus half fbox_overhead to center over the VISIBLE box
  -- (fbox has border+padding on left side that shifts the visible area right)
  local header_offset = left_margin + fbox_overhead / 2
  tex.print(string.format([[\noindent\kern%.5fin]], header_offset))
  for i, label in ipairs(top_labels) do
    tex.print(string.format([[{\hbox to %.5fin{\hfil %s %s\hfil}}]], cell_pitch, top_font, label))
  end
  tex.print([[\par\vskip2pt\noindent]])

  -- Debug: measure actual TeX placement by typesetting and walking the node list
  -- Store sp2in in a global for the deferred callbacks
  _G._debug_sp2in = gridlib.sp2in

  -- Helper to walk an hbox and find child box midpoints
  -- Node type IDs (from node.type()): 0=hlist, 1=vlist, 12=glue, 13=kern
  local function get_box_midpoints(boxnum)
    local midpoints = {}
    local box = tex.getbox(boxnum)
    if not box then return midpoints end
    local pos = 0
    for nd in node.traverse(box.head) do
      local id = nd.id
      if id == 0 or id == 1 then -- hlist or vlist
        local mid = pos + nd.width / 2
        table.insert(midpoints, _G._debug_sp2in(mid))
        pos = pos + nd.width
      elseif id == 13 then -- kern
        pos = pos + nd.kern
      elseif id == 12 then -- glue
        pos = pos + nd.width
      end
    end
    return midpoints
  end

  -- Store functions globally for deferred execution
  _G._get_box_midpoints = get_box_midpoints
  _G._header_mids = {}
  _G._grid_mids = {}
  _G._print_alignment_debug = function()
    local fbox_border = 3.4 / 72  -- fboxrule + fboxsep = 0.4pt + 3pt = 3.4pt per side
    texio.write_nl("Column alignment (measured from TeX nodes):")
    texio.write_nl(string.format("  Header row total width: %.4fin", _G._debug_sp2in(tex.getbox(1).width)))
    texio.write_nl(string.format("  Grid row total width:   %.4fin", _G._debug_sp2in(tex.getbox(2).width)))
    texio.write_nl(string.format("  fbox border/padding per side: %.4fin (%.1fpt)", fbox_border, fbox_border * 72))
    texio.write_nl("  Comparing header center to VISIBLE box center:")
    texio.write_nl("  (header includes fbox_border offset to center over visible box)")
    for i = 1, math.min(#_G._header_mids, #_G._grid_mids) do
      -- Header measurement already includes fbox_border kern, visible box is grid_mid + fbox_border
      local visible_box_mid = _G._grid_mids[i] + fbox_border
      local diff = _G._header_mids[i] - visible_box_mid
      texio.write_nl(string.format("  Col %2d: header=%.4fin, visible_box=%.4fin, diff=%.4fin",
        i, _G._header_mids[i], visible_box_mid, diff))
    end
  end

  -- Build and measure header row (with the fbox_overhead/2 offset, just the header boxes)
  tex.sprint(string.format([[\setbox1=\hbox{\kern%.5fin]], fbox_overhead / 2))
  for i, label in ipairs(top_labels) do
    tex.sprint(string.format([[{\hbox to %.5fin{\hfil %s %s\hfil}}]], cell_pitch, top_font, label))
  end
  tex.sprint([[}\directlua{_G._header_mids = _G._get_box_midpoints(1)}]])

  -- Build and measure grid row (just the fboxes, not the left label)
  tex.sprint([[\setbox2=\hbox{]])
  for col = 1, num_cols do
    tex.sprint(string.format([[\fbox{\vbox to %.5fin{\vfil\hbox to %.5fin{\hfil}\vfil}}]], box_height, box_width))
  end
  tex.sprint([[}\directlua{_G._grid_mids = _G._get_box_midpoints(2)}]])

  -- Measure the left label vbox width
  tex.sprint(string.format([[\setbox3=\hbox{\vbox to %.5fin{\vfil\hbox to %.5fin{\hfil}\vfil}}]], box_height, left_margin))

  -- Measure the header kern width
  tex.sprint(string.format([[\setbox4=\hbox{\kern%.5fin}]], left_margin))

  -- Print debug output after measurements
  tex.sprint([[\directlua{_G._print_alignment_debug()}]])

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

-- Month names
gridlib.month_names = {
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
}

-- Month name abbreviations
gridlib.month_names_short = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}


-- Print pdfcrop command for extracting a test section from the PDF
-- Parameters:
--   pdf_name: output PDF filename (e.g., "calendar.pdf")
--   paper_width, paper_height: full page dimensions in inches
--   test_width, test_height: size of test section to extract (default: 8.5x11)
function gridlib.print_crop_command(pdf_name, paper_width, paper_height, test_width, test_height)
  test_width = test_width or 8.5
  test_height = test_height or 11
  local crop_width = test_width * 72  -- convert to points
  local crop_height = test_height * 72  -- convert to points
  local total_height = paper_height * 72  -- total page height in points
  local crop_bottom = total_height - crop_height
  local output_name = pdf_name:gsub("%.pdf$", "") .. "-test.pdf"
  texio.write_nl(string.format('**********************************'))
  texio.write_nl(string.format('To print upper-left %.1fx%.1f test section, run:', test_width, test_height))
  texio.write_nl(string.format('pdfcrop --bbox "0 %.0f %.0f %.0f" %s %s',
    crop_bottom, crop_width, total_height, pdf_name, output_name))
  texio.write_nl(string.format('**********************************'))
end

return gridlib
