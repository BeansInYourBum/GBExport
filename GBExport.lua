if app.sprite == nil then
	app.alert{ title = "GBExport Error", text = "No sprite is active" }
	return
end
local folder = app.fs.filePath(app.sprite.filename)
if folder == "" then
	folder = app.fs.userDocsPath..app.fs.pathSeparator
else
	folder = folder..app.fs.pathSeparator
end


local tilemap_names = { }
local tilemap_layers = { }
for index, layer in ipairs(app.sprite.layers) do
	if layer.isTilemap then
		tilemap_names[#tilemap_names + 1] = layer.name
		tilemap_layers[#tilemap_layers + 1] = layer
	end
end
local tag_names = { }
local tag_frames = { }
if #tilemap_layers == 0 and #app.sprite.tags >= 1 then
	tag_names[#tag_names + 1] = "--- All Frames ---" 
	for index, tag in ipairs(app.sprite.tags) do
		tag_names[#tag_names + 1] = tag.name
		tag_frames[#tag_frames + 1] = Point(tag.fromFrame.frameNumber, tag.frames)
	end
end


local selected_tag = nil
local selected_tileset = nil
local selected_tilemap = nil
local dialog = Dialog("GBExport")
dialog:label{ text = "Select what to export" }
dialog:check{
	id = "export_sprite",
	text = "Sprite",
	selected = false,
	onclick = function()
		local data = dialog.data;
		dialog:modify{
			id = "sprite_label",
			visible = data.export_sprite
		}
		dialog:modify{
			id = "sprite_tag",
			visible = data.export_sprite and #tag_names >= 1
		}
		dialog:modify{
			id = "sprite_file",
			visible = data.export_sprite
		}
	end,
	visible = #tilemap_layers == 0
}
dialog:check{
	id = "export_tileset",
	text = "Tileset",
	selected = false,
	onclick = function()
		local data = dialog.data;
		dialog:modify{
			id = "tileset_label",
			visible = data.export_tileset
		}
		dialog:modify{
			id = "tileset_layer",
			visible = data.export_tileset
		}
		dialog:modify{
			id = "tileset_file",
			visible = data.export_tileset
		}
	end,
	visible = #tilemap_names >= 1
}
dialog:check{
	id = "export_tilemap",
	text = "Tilemap",
	selected = false,
	onclick = function()
		local data = dialog.data;
		dialog:modify{
			id = "tilemap_label",
			visible = data.export_tilemap
		}
		dialog:modify{
			id = "tilemap_layer",
			visible = data.export_tilemap
		}
		dialog:modify{
			id = "tilemap_padding",
			visible = data.export_tilemap
		}
		dialog:modify{
			id = "tilemap_file",
			visible = data.export_tilemap
		}
	end,
	visible = #tilemap_names >= 1
}
dialog:label{
	id = "sprite_label",
	text = "Sprite details",
	visible = false
}
dialog:combobox{
	id = "sprite_tag",
	label = "Tag",
	option = #tag_names >= 1 and tag_names[1] or "",
	options = tag_names,
	visible = false
}
dialog:file{
	id = "sprite_file",
	label = "Output",
	filename = folder.."Sprite.bin",
	filetypes = { "bin" },
	open = false,
	save = true,
	visible = false
}
dialog:label{
	id = "tileset_label",
	text = "Tileset details",
	visible = false
}
dialog:combobox{
	id = "tileset_layer",
	label = "Layer",
	option = #tilemap_names >= 1 and tilemap_names[1] or "",
	options = tilemap_names,
	visible = false
}
dialog:file{
	id = "tileset_file",
	label = "Output",
	filename = folder.."Tileset.bin",
	filetypes = { "bin" },
	open = false,
	save = true,
	visible = false
}
dialog:label{
	id = "tilemap_label",
	text = "Tilemap details",
	visible = false
}
dialog:combobox{
	id = "tilemap_layer",
	label = "Layer",
	option = #tilemap_names >= 1 and tilemap_names[1] or "",
	options = tilemap_names,
	visible = false
}
dialog:check {
	id = "tilemap_padding",
	text = "Padding",
	selected = false,
	visible = false,
}
dialog:file{
	id = "tilemap_file",
	label = "Output",
	filename = folder.."Tilemap.bin",
	filetypes = { "bin" },
	open = false,
	save = true,
	visible = false
}
dialog:separator{ }
dialog:button{
	id = "accept",
	text = "Accept",
	onclick = function()
		local data = dialog.data
		if data.export_tileset and data.export_tilemap and data.tileset_file == data.tilemap_file then
			app.alert{ title = "GBExport Error", text = "Output files must be unique" }
			return
		end
		if data.export_sprite then
			if app.sprite.width ~= 8 or app.sprite.height ~= 8 then
				app.alert{ title = "GBExport Error", text = "Sprite size isn't 8x8" }
				return
			end
			if #tag_names >= 1 and data.sprite_tag ~= "--- All Frames ---" then
				for index, name in ipairs(tag_names) do
					if data.sprite_tag == name then
						selected_tag = tag_frames[index - 1]
						break
					end
				end
			end
		end
		if data.export_tileset then
			local layer = nil
			for index, name in ipairs(tilemap_names) do
				if data.tileset_layer == name then
					layer = tilemap_layers[index]
					break
				end
			end
			if layer == nil then
				app.alert{ title = "GBExport Error", text = "Failed to find tileset layer" }
				return
			end
			local tile = layer.tileset:tile(0)
			if tile.image.width ~= 8 or tile.image.height ~= 8 then
				app.alert{ title = "GBExport Error", text = "Specified tileset tile size isn't 8x8" }
				return
			end
			selected_tileset = layer.tileset
		end
		if data.export_tilemap then
			local layer = nil
			for index, name in ipairs(tilemap_names) do
				if data.tilemap_layer == name then
					layer = tilemap_layers[index]
					break
				end
			end
			if layer == nil then
				app.alert{ title = "GBExport Error", text = "Failed to find tilemap layer" }
				return
			end
			local tile = layer.tileset:tile(0)
			if tile.image.width ~= 8 or tile.image.height ~= 8 then
				app.alert{ title = "GBExport Error", text = "Specified tilemap tile size isn't 8x8" }
				return
			end
			local image = layer:cel().image
			if image.width > 32 or image.height > 32 then
				app.alert{ title = "GBExport Error", text = "Specified tilemap grid size is too large" }
				return
			end
			selected_tilemap = image
		end
		dialog:close()
	end
}
dialog:button{
	text = "Cancel",
	onclick = function()
		dialog:close()
	end
}
dialog:show{ wait = true }
local dialog_data = dialog.data
if not dialog_data.accept then return end


if dialog_data.export_sprite then
	local file_data = ""
	local from = 1
	local to = #app.sprite.frames
	if selected_tag ~= nil then
		from = selected_tag.x
		to = from + selected_tag.y - 1
	end
	for index = from, to do
		local cel = app.sprite.cels[app.sprite.frames[index].frameNumber]
		local bounds_left = cel.bounds.x
		local bounds_right = bounds_left + cel.bounds.width
		local bounds_top = cel.bounds.y
		local bounds_bottom = bounds_top + cel.bounds.height
		local image = cel.image
		for y = 0, app.sprite.height - 1 do
			local left = 0
			local right = 0
			for x = 0, app.sprite.width - 1 do
				if x >= bounds_left and x < bounds_right and y >= bounds_top and y < bounds_bottom then
					local colour = image:getPixel(x - bounds_left, y - bounds_top)
					if app.sprite.colorMode == ColorMode.INDEXED then
						colour = app.sprite.palettes[1]:getColor(colour)
					else
						colour = Color(app.pixelColor.rgbaR(colour), app.pixelColor.rgbaG(colour), app.pixelColor.rgbaB(colour))
					end
					local value = 3 - ((math.max(colour.red, math.max(colour.green, colour.blue)) >> 6) & 3)
					left = left | (value & 1) << (8 - (x + 1))
					right = right | ((value >> 1) & 1) << (8 - (x + 1))
				end
			end
			file_data = file_data..string.char(left)..string.char(right)
		end
	end
	local file = io.open(dialog_data.sprite_file, "wb")
	file:write(file_data)
	file:close()
end
if dialog_data.export_tileset then
	local file_data = ""
	for index = 1, #selected_tileset - 1 do
		local image = selected_tileset:tile(index).image
		for y = 0, image.height - 1 do
			local left = 0
			local right = 0
			for x = 0, image.width - 1 do
				local colour = image:getPixel(x, y)
				if app.sprite.colorMode == ColorMode.INDEXED then
					colour = app.sprite.palettes[1]:getColor(colour)
				else
					colour = Color(app.pixelColor.rgbaR(colour), app.pixelColor.rgbaG(colour), app.pixelColor.rgbaB(colour))
				end
				local value = 3 - ((math.max(colour.red, math.max(colour.green, colour.blue)) >> 6) & 3)
				left = left | (value & 1) << (8 - (x + 1))
				right = right | ((value >> 1) & 1) << (8 - (x + 1))
			end
			file_data = file_data..string.char(left)..string.char(right)
		end
	end
	local file = io.open(dialog_data.tileset_file, "wb")
	file:write(file_data)
	file:close()
end
if dialog_data.export_tilemap then
	local file_data = ""
	for y = 0, selected_tilemap.height - 1 do
		for x = 0, selected_tilemap.width - 1 do
			file_data = file_data..string.char(selected_tilemap:getPixel(x, y) - 1)
		end
		if dialog_data.tilemap_padding then
			for x = selected_tilemap.width + 1, 32 do
				file_data = file_data..string.char(0)
			end
		end
	end
	local file = io.open(dialog_data.tilemap_file, "wb")
	file:write(file_data)
	file:close()
end

