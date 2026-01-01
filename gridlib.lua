-- gridlib.lua: Shared grid drawing library for LaTeX documents

local gridlib = {}

-- Internal helper: parse common grid options with defaults
local function parse_grid_options(options)
  options = options or {}
  return {
    -- Font sizes: \tiny \scriptsize \footnotesize \small \normalsize
    -- \large \Large \LARGE \huge \Huge
    top_font = options.top_font_size or [[\Huge\bfseries]],
    left_font = options.left_font_size or [[\Huge\bfseries]],
    left_margin = options.left_margin or 1.0,
    header_height = options.header_height or 0.4,
    gap = options.gap or 0.06,
    line_width = options.line_width or 1.2,
    cell_content = options.cell_content,
    divider_style = options.divider_style,  -- default set below after line_width is known
  }
end

-- Internal helper: draw row labels on the left side
local function draw_row_labels(left_labels, left_margin, cell_height, gap, box_area_height, font)
  for row = 1, #left_labels do
    local x = left_margin / 2
    local y = box_area_height - (row - 1) * (cell_height + gap) - cell_height / 2
    tex.print(string.format([=[\node[font=%s] at (%.4f, %.4f) {%s};]=],
      font, x, y, left_labels[row]))
  end
end

-- Internal helper: draw column labels along the top
local function draw_column_labels(top_labels, left_margin, cell_width, height, header_height, font, col_x_fn)
  for col = 1, #top_labels do
    local x = col_x_fn(col, left_margin, cell_width)
    local y = height - header_height / 2
    tex.print(string.format([=[\node[font=%s] at (%.4f, %.4f) {%s};]=],
      font, x, y, top_labels[col]))
  end
end

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

-- Draw a grid using TikZ with labels along the top and left side
-- Parameters:
--   width: total width of grid area in inches
--   height: total height of grid area in inches
--   top_labels: array of strings for column headers
--   left_labels: array of strings for row headers
--   options: table with optional settings:
--     top_font_size: TeX font size command (default: \Huge)
--     left_font_size: TeX font size command (default: \Huge)
--     left_margin: width in inches for left label column (default: 1.0)
--     header_height: height in inches for top label row (default: 0.5)
--     gap: gap between boxes in inches (default: 0.04)
--     line_width: box border thickness in points (default: 0.4)
--     cell_content: function(row, col) returning TeX string for cell content (default: nil)
function gridlib.draw_grid(width, height, top_labels, left_labels, options)
  local opts = parse_grid_options(options)
  local num_cols = #top_labels
  local num_rows = #left_labels

  -- Calculate cell dimensions
  local box_area_width = width - opts.left_margin
  local box_area_height = height - opts.header_height

  local cell_width = (box_area_width - (num_cols - 1) * opts.gap) / num_cols
  local cell_height = (box_area_height - (num_rows - 1) * opts.gap) / num_rows

  texio.write_nl(string.format('TikZ grid - Total: %.3fin x %.3fin, Cell: %.3fin x %.3fin', width, height, cell_width, cell_height))

  -- Start TikZ picture
  tex.print([=[\noindent\begin{tikzpicture}[x=1in, y=1in]]=])

  -- Draw column labels (top) - x position accounts for gap between cells
  draw_column_labels(top_labels, opts.left_margin, cell_width, height, opts.header_height, opts.top_font,
    function(col, left_margin, cw)
      return left_margin + (col - 1) * (cw + opts.gap) + cw / 2
    end)

  -- Draw row labels (left)
  draw_row_labels(left_labels, opts.left_margin, cell_height, opts.gap, box_area_height, opts.left_font)

  -- Draw grid of boxes
  for row = 1, num_rows do
    for col = 1, num_cols do
      local x = opts.left_margin + (col - 1) * (cell_width + opts.gap)
      local y = box_area_height - (row - 1) * (cell_height + opts.gap) - cell_height
      tex.print(string.format([=[\draw[line width=%.1fpt] (%.4f, %.4f) rectangle (%.4f, %.4f);]=],
        opts.line_width, x, y, x + cell_width, y + cell_height))

      -- Draw cell content if provided (bottom-left aligned)
      if opts.cell_content then
        local content = opts.cell_content(row, col)
        if content and content ~= "" then
          tex.print(string.format([=[\node[anchor=south west, inner sep=2pt] at (%.4f, %.4f) {%s};]=],
            x, y, content))
        end
      end
    end
  end

  tex.print([=[\end{tikzpicture}]=])

  return {
    cell_width = cell_width,
    cell_height = cell_height
  }
end


-- Draw a grid using TikZ with each row as a single box with dotted internal dividers
-- Parameters same as draw_grid, plus:
--   options.divider_style: TikZ style for internal dividers (default: "dotted, line width=0.4pt")
function gridlib.draw_grid_rowbox(width, height, top_labels, left_labels, options)
  local opts = parse_grid_options(options)
  local divider_style = opts.divider_style or "dashed"
  if not divider_style:find("line width") then
    divider_style = string.format("%s, line width=%.1fpt", divider_style, opts.line_width)
  end
  opts.divider_style = divider_style

  local num_cols = #top_labels
  local num_rows = #left_labels

  -- Calculate cell dimensions
  local box_area_width = width - opts.left_margin
  local box_area_height = height - opts.header_height

  local row_width = box_area_width
  local cell_width = box_area_width / num_cols
  local cell_height = (box_area_height - (num_rows - 1) * opts.gap) / num_rows

  texio.write_nl(string.format('TikZ rowbox grid - Total: %.3fin x %.3fin, Cell: %.3fin x %.3fin', width, height, cell_width, cell_height))

  -- Start TikZ picture
  tex.print([=[\noindent\begin{tikzpicture}[x=1in, y=1in]]=])

  -- Draw column labels (top) - x position centered in cell (no gap between cells)
  draw_column_labels(top_labels, opts.left_margin, cell_width, height, opts.header_height, opts.top_font,
    function(col, left_margin, cw)
      return left_margin + (col - 0.5) * cw
    end)

  -- Draw row labels (left)
  draw_row_labels(left_labels, opts.left_margin, cell_height, opts.gap, box_area_height, opts.left_font)

  -- Draw each row as a single box with internal dotted dividers
  for row = 1, num_rows do
    local row_x = opts.left_margin
    local row_y = box_area_height - (row - 1) * (cell_height + opts.gap) - cell_height

    -- Draw the outer rectangle for the entire row
    tex.print(string.format([=[\draw[line width=%.1fpt] (%.4f, %.4f) rectangle (%.4f, %.4f);]=],
      opts.line_width, row_x, row_y, row_x + row_width, row_y + cell_height))

    -- Draw dotted vertical dividers between columns (not at edges)
    for col = 2, num_cols do
      local divider_x = row_x + (col - 1) * cell_width
      tex.print(string.format([=[\draw[%s] (%.4f, %.4f) -- (%.4f, %.4f);]=],
        opts.divider_style, divider_x, row_y, divider_x, row_y + cell_height))
    end

    -- Draw cell content if provided
    if opts.cell_content then
      for col = 1, num_cols do
        local content = opts.cell_content(row, col)
        if content and content ~= "" then
          local cell_x = row_x + (col - 1) * cell_width
          tex.print(string.format([=[\node[anchor=south west, inner sep=2pt] at (%.4f, %.4f) {%s};]=],
            cell_x, row_y, content))
        end
      end
    end
  end

  tex.print([=[\end{tikzpicture}]=])

  return {
    cell_width = cell_width,
    cell_height = cell_height
  }
end

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


return gridlib