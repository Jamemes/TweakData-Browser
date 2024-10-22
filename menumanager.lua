Hooks:Add("LocalizationManagerPostInit", "TweakdataListGui_loc", function(...)		
	LocalizationManager:add_localized_strings({
		menu_tweakdata_browser = "TweakData Browser"
	})
end)

TweakdataListGui = TweakdataListGui or class(MenuGuiComponentGeneric)

local function type_format(val)
	if type(val) == "number" then
		return "[" .. tostring(val) .. "]"
	else
		return "." .. tostring(val)
	end
end

local function build_table(tbl)
	local text = ""
	local i = 0
	for k, v in pairs(tbl) do
		i = i + 1
		local comma = i == table.size(tbl) and "" or ", "
		text = text .. tostring(k) .. comma
	end
	
	text = "{ " .. text .. " }"

	return text
end

function TweakdataListGui:digest_value_reveal(value)
	if table.contains(self._table_path, "money_manager") or table.contains(self._table_path, "experience_manager") then
		if type(value) == "string" then
			value = tonumber(Application:digest_value(value, false))
		end
	end
	
	return value
end

function TweakdataListGui:table_to_browse()
	if table.size(self._table_path) == 0 then
		return tweak_data
	end
	
	local path = nil
	for i = 1, #self._table_path do
		if i == 1 then
			path = tweak_data[self._table_path[1]]
		elseif type(path) == "number" then
			path = path[tonumber(self._table_path[i])]
		else
			path = path[self._table_path[i]]
		end
	end

	return path
end
			
local padding = 10
function TweakdataListGui:_setup(is_start_page, component_data)
	TweakdataListGui.super._setup(self, is_start_page, component_data)

	self._tweak_panel = self._panel:panel({layer = 200})
	self._title_text:set_layer(200)
	self._panel:child("back_button"):set_layer(200)
	self._outline_panel:hide()
	self._title_text:set_text("TweakData Browser")
	self:make_fine_text(self._title_text)

	self._tweakdata_path = self._tweak_panel:text({
		name = "tweakdata_path",
		text = "tweak_data",
		font_size = tweak_data.menu.pd2_medium_font_size,
		font = tweak_data.menu.pd2_medium_font,
		color = tweak_data.screen_colors.text
	})
	self:make_fine_text(self._tweakdata_path)
	self._tweakdata_path:set_righttop(self._tweak_panel:right(), self._tweak_panel:top())

	self._searchbox = SearchBoxGuiObject:new(self._tweak_panel, self._ws, self._last_search)
	SearchBoxGuiObject.MAX_SEARCH_LENGTH = 256

	self._searchbox.panel:set_w(800)
	self._searchbox.panel:child(0):set_w(self._searchbox.panel:w())
	self._searchbox.panel:child(1):hide()
	self._searchbox.placeholder_text:set_w(self._searchbox.panel:w())
	self._searchbox.placeholder_text:set_center_x(self._searchbox.panel:w() / 2)
	self._searchbox.text:set_w(self._searchbox.panel:w())
	self._searchbox.text:set_center_x(self._searchbox.panel:w() / 2)
	BoxGuiObject:new(self._searchbox.panel, {
		sides = { 1, 1, 1, 1 }
	})
	
	self._searchbox.panel:set_center_x(self._searchbox.panel:parent():w() * 0.5)
	self._searchbox.panel:set_bottom(self._tweak_panel:bottom() - 30)
	self._searchbox:register_callback(callback(self, self, "update_search", false))

	local large_font_size = tweak_data.menu.pd2_large_font_size
	local scroll_panel = self._tweak_panel:panel({
		h = self._tweak_panel:h() - large_font_size * 2 - padding * 2,
		y = large_font_size
	})
	self._scroll = ScrollablePanel:new(scroll_panel, "mods_scroll", {})
	self._table_path = {}
	self:open_tweak_table(tweak_data)
end

function TweakdataListGui:update_search(scroll_position, search_list, search_text)
	if self._edit_value then
		return
	end
	
	self._last_search = search_text
	local tbl = {}
	for key, value in pairs(self:table_to_browse()) do
		local value_text = nil
		if type(value) == "table" then
			value_text = build_table(value)
		end
			
		if tostring(key):lower():find(search_text) or (value_text and value_text:lower():find(search_text) or tostring(value):lower():find(search_text)) then
			tbl[key] = value
		end
	end
	
	self:open_tweak_table(tbl)
end

function TweakdataListGui:open_tweak_table(tbl)
	if #self._table_path ~= 0 then
		managers.menu:active_menu().logic:selected_node():parameters().block_back = true
		self._panel:child("back_button"):set_text(utf8.to_upper(managers.localization:text("menu_back")):gsub([[ESC]], [[RMB]]))
		self:make_fine_text(self._panel:child("back_button"))
		self._panel:child("back_button"):set_right(self._panel:w())
	else
		managers.menu:active_menu().logic:selected_node():parameters().block_back = false
		self._panel:child("back_button"):set_text(utf8.to_upper(managers.localization:text("menu_back")))
		self:make_fine_text(self._panel:child("back_button"))
		self._panel:child("back_button"):set_right(self._panel:w())
	end
	
	if not self._searchbox._focus or self._edit_value then
		self._searchbox:clear_text()
		self._searchbox:update_caret()
		self._searchbox:disconnect_search_input()
		self._edit_value = nil
	end
		
	-- Clear the scroll panel
	self._scroll:canvas():clear()
	self._scroll:update_canvas_size() -- Ensure the canvas always starts at it's maximum size

	local y = 0
	for name, value in pairs(tbl) do
		value = self:digest_value_reveal(value)

		local medium_font = tweak_data.menu.pd2_medium_font
		local small_font = tweak_data.menu.pd2_small_font
		local medium_font_size = tweak_data.menu.pd2_medium_font_size
		local small_font_size = tweak_data.menu.pd2_small_font_size
		local tweak_panel = self._scroll:canvas():panel({
			name = tostring(name) .. "_button",
			y = y,
			h = medium_font_size * 1.2,
			w = self._scroll:canvas():w() - (padding * 2),
			layer = 10
		})

		tweak_panel:bitmap({
			texture = "guis/textures/test_blur_df",
			w = tweak_panel:w(),
			h = tweak_panel:h(),
			render_template = "VertexColorTexturedBlur3D",
			layer = -1,
			halign = "scale",
			valign = "scale"
		})

		local tweak_name = tweak_panel:text({
			name = "tweak_name",
			font_size = tweak_data.menu.pd2_medium_font_size * 1.2,
			font = tweak_data.menu.pd2_medium_font,
			layer = 10,
			blend_mode = "add",
			text = tostring(name),
			align = "left"
		})
	
		self:make_fine_text(tweak_name)
		tweak_name:set_left(tweak_panel:left() + padding)
		tweak_name:set_y(tweak_panel:h() * 0.5)

		local type_text = type(value)
		local value_text = tostring(value)
		local color = Color.white
		if type(value) == "table" then
			type_text = tostring(tbl[name]) .. " = {" .. table.size(tbl[name]) .. "}"
			value_text = tostring(build_table(value))
			color = Color("9E9D2E")
			if table.size(value) > 10 then
				medium_font_size = math.ceil(medium_font_size / (1 + table.size(value) * 0.01))
			end
		elseif type(value) == "boolean" then
			color = Color("4F6CFF")
		elseif type(value) == "string" then
			value_text = [["]] .. tostring(value) .. [["]]
			color = Color("CD7272")
		elseif type(value) == "number" then
			color = Color("56CCD1")
		elseif type(value) == "userdata" then
			type_text = type(value) .. ": " .. value_text
		end

		local tweak_type = tweak_panel:text({
			y = 5,
			name = "tweak_type",
			font_size = tweak_data.menu.pd2_medium_font_size / 1.5,
			font = medium_font,
			layer = 10,
			text = type_text,
			alpha = 0.6,
			color = color,
		})
		
		self:make_fine_text(tweak_type)
		tweak_type:set_right(tweak_panel:right() - padding)
		
		local tweak_value = tweak_panel:text({
			name = "tweak_value",
			wrap = true,
			word_wrap = true,
			font_size = medium_font_size,
			font = medium_font,
			layer = 10,
			blend_mode = "add",
			text = value_text,
			color = color,
			align = "right",
			vertical = "top"
		})
		
		tweak_value:set_w(math.round(tweak_panel:w() - tweak_name:w() - 120))
		self:make_fine_text(tweak_value)
		tweak_value:set_righttop(tweak_panel:right() - padding, tweak_type:bottom())

		local hsv_adjust = 0
		if type(value) == "userdata" and value_text:find("Color") then
			tweak_value:set_h(tweak_value:h())
			tweak_value:set_text("")
			
			local rect_panel = tweak_panel:panel({name = "rect"})
			rect_panel:set_size(tweak_value:h() * 2.5, tweak_value:h() * 2.5)
			rect_panel:set_righttop(tweak_value:right(), tweak_type:bottom() + 5)
			
			rect_panel:rect({
				name = "color",
				color = value,
				blend_mode = "normal"
			})
			BoxGuiObject:new(rect_panel, {sides = {1, 1, 1, 1}})
			
			local h, s, v = rgb_to_hsv(value.r, value.g, value.b)
			local hsv = tweak_panel:text({
				name = "hsv",
				font_size = medium_font_size / 1.5,
				font = medium_font,
				layer = 10,
				blend_mode = "add",
				text = string.format("Hue: %s\nSaturation: %s\nValue: %s\nAlpha: %s", h, s, v, string.sub(tostring(value), 7, tostring(value):find("*") - 2)),
				align = "right",
				vertical = "top"
			})
			self:make_fine_text(hsv)
			hsv:set_righttop(rect_panel:left() - 15, rect_panel:top())
			hsv_adjust = hsv:bottom()
		end
		
		tweak_panel:set_h(math.max(tweak_name:bottom(), tweak_value:bottom(), hsv_adjust) + padding)

		-- Background
		tweak_panel:rect({
			name = "background",
			color = Color.black,
			blend_mode = "normal",
			alpha = 0.6,
			layer = -1
		})

		BoxGuiObject:new(tweak_panel, {sides = {1, 1, 1, 1}})
		
		y = y + tweak_panel:h() + padding
	end

	-- Update scroll size
	self._scroll:update_canvas_size()
end

function TweakdataListGui:mouse_moved(button, x, y)
	local used, pointer = TweakdataListGui.super.mouse_moved(self, button, x, y)

	if not used then
		used, pointer = self._scroll:mouse_moved(button, x, y)
	end
	
	if not used then
		used, pointer = self._searchbox:mouse_moved(button, x, y)
	end
	
	local inside_scroll = alive(self._scroll) and self._scroll:panel():inside(x, y)
	for name, val in pairs(self:table_to_browse()) do
		if not used and alive(self._scroll:canvas():child(name .. "_button")) and self._scroll:canvas():child(name .. "_button"):inside(x, y) and inside_scroll then	
			local path = "tweak_data"
			if #self._table_path ~= 0 then
				for i = 1, #self._table_path do
					path = path .. type_format(self._table_path[i])
				end
			end
			
			path = path .. type_format(name)
			
			self._tweakdata_path:set_font_size(tweak_data.menu.pd2_medium_font_size)
			self._tweakdata_path:set_text(path)
			local _, _, w, h = self._tweakdata_path:text_rect()
			while w > self._tweak_panel:w() / 1.3 do
				self._tweakdata_path:set_font_size(self._tweakdata_path:font_size() * 0.99)
				_, _, w, h = self._tweakdata_path:text_rect()
			end
			
			self:make_fine_text(self._tweakdata_path)
			self._tweakdata_path:set_righttop(self._tweak_panel:right(), self._tweak_panel:top())
			self._scroll:canvas():child(name .. "_button"):child("background"):set_color(Color(0.15, 0.15, 0.15))
			used, pointer = true, "link"
		elseif alive(self._scroll:canvas():child(name .. "_button")) then
			self._scroll:canvas():child(name .. "_button"):child("background"):set_color(Color.black)
		end
	end

	return used, pointer
end

function TweakdataListGui:mouse_pressed(button, x, y)
	
	TweakdataListGui.super.mouse_pressed(self, button, x, y)

	self._searchbox:mouse_pressed(button, x, y)
	self._scroll:mouse_pressed(button, x, y)

	local edited_text = self._searchbox.text:text()
	if edited_text and self._edit_value then
		local value_type = type(self:digest_value_reveal(self:table_to_browse()[self._edit_value]))
		if value_type == "string" then
		elseif value_type == "boolean" then
			local sbt = self._searchbox.text:text()
			if sbt == "t" or sbt == "tr" or sbt == "tru" or sbt == "true" then
				edited_text = true
			elseif sbt == "f" or sbt == "fa" or sbt == "fal" or sbt == "fals" or sbt == "false" then
				edited_text = false
			end
		elseif value_type == "number" then
			edited_text = tonumber(edited_text)
		elseif value_type == "userdata" then
			if tostring(self:digest_value_reveal(self:table_to_browse()[self._edit_value])):find("Color") then
				local hsv = string.split(edited_text, "|")
				if table.size(hsv) == 4 then
					edited_text = Color(CoreMath.hsv_to_rgb(hsv[1], hsv[2], hsv[3])):with_alpha(hsv[4])
				else
					edited_text = nil
				end
			elseif tostring(self:digest_value_reveal(self:table_to_browse()[self._edit_value])):find("Vector3") or tostring(self:digest_value_reveal(self:table_to_browse()[self._edit_value])):find("Rotation") then
				local xyz = string.split(tostring(edited_text), "|")

				if table.size(xyz) == 3 then
					edited_text = Vector3(xyz[1], xyz[2], xyz[3])
				else
					edited_text = nil
				end
			end
		else
			edited_text = nil
		end

		if edited_text ~= nil and edited_text ~= "" then
			edited_text = self:digest_value_reveal(edited_text)
			
			if self:digest_value_reveal(edited_text) ~= self:table_to_browse()[self._edit_value] then
				self:table_to_browse()[self._edit_value] = edited_text
			end
			
			local tweak_panel = self._scroll:canvas():child(self._edit_value .. "_button")
			local tweak_value = self._scroll:canvas():child(self._edit_value .. "_button"):child("tweak_value")
			local tweak_type = self._scroll:canvas():child(self._edit_value .. "_button"):child("tweak_type")
			local hsv = self._scroll:canvas():child(self._edit_value .. "_button"):child("hsv")
			if type(edited_text) == "userdata" then
				tweak_type:set_text(type(edited_text) .. ": " .. tostring(edited_text))
				self:make_fine_text(tweak_type)
				tweak_type:set_right(tweak_panel:right() - padding)
				if tostring(edited_text):find("Color") then
					tweak_panel:child("rect"):child("color"):set_color(edited_text)
		
					local h, s, v = rgb_to_hsv(edited_text.r, edited_text.g, edited_text.b)
					hsv:set_text(string.format("Hue: %s\nSaturation: %s\nValue: %s\nAlpha: %s", h, s, v, string.sub(tostring(edited_text), 7, tostring(edited_text):find("*") - 2)))
					self:make_fine_text(hsv)
					hsv:set_righttop(tweak_panel:child("rect"):left() - 15, tweak_panel:child("rect"):top())
				elseif tostring(edited_text):find("Vector3") or tostring(browser[name]):find("Rotation") then
					tweak_value:set_text(tostring(edited_text))
					tweak_value:set_w(math.round(tweak_panel:w() - tweak_panel:child("tweak_name"):w() - 120))
					self:make_fine_text(tweak_value)
					tweak_value:set_righttop(tweak_panel:right() - padding, tweak_panel:child("tweak_type"):bottom())	
				end
			else
				tweak_value:set_text(type(edited_text) == "string" and [["]] .. edited_text .. [["]] or tostring(edited_text))
				tweak_value:set_w(math.round(tweak_panel:w() - tweak_panel:child("tweak_name"):w() - 120))
				self:make_fine_text(tweak_value)
				tweak_value:set_righttop(tweak_panel:right() - padding, tweak_panel:child("tweak_type"):bottom())
			end
			
			self._searchbox:clear_text()
			self._searchbox:update_caret()
			self._searchbox:disconnect_search_input()
			self._edit_value = nil
		end
	end
	
	local inside_scroll = alive(self._scroll) and self._scroll:panel():inside(x, y)
	local browser = self:table_to_browse()
	for name, _ in pairs(browser) do
		if self._scroll and self._scroll:canvas():child(name .. "_button") then
			if button == Idstring("0") and self._scroll:canvas():child(name .. "_button"):inside(x, y) and inside_scroll then
				if browser[name] and type(browser[name]) == "table" then
					if table.size(browser[name]) ~= 0 then
						table.insert(self._table_path, name)
						self:open_tweak_table(self:table_to_browse())
					end
				elseif browser[name] and type(browser[name]) == "userdata" then
					if tostring(browser[name]):find("Color") then
						self._edit_value = name
						local h, s, v = rgb_to_hsv(browser[name].r, browser[name].g, browser[name].b)
						local hsv = h .. "|" .. s  .. "|" .. v .. "|" .. string.sub(tostring(browser[name]), 7, tostring(browser[name]):find("*") - 2)
						self._searchbox.text:set_text(hsv)
						local n = utf8.len(hsv)
						self._searchbox.text:set_selection(n, n)
						self._searchbox:connect_search_input()
					elseif tostring(browser[name]):find("Vector3") or tostring(browser[name]):find("Rotation") then
						self._edit_value = name
						local xyz = nil
						if tostring(browser[name]):find("Vector3") then
							xyz = browser[name].x .. "|" .. browser[name].y  .. "|" .. browser[name].z
						elseif tostring(browser[name]):find("Rotation") then
							xyz = browser[name]:yaw() .. "|" .. browser[name]:pitch()  .. "|" .. browser[name]:roll()
						end
						self._searchbox.text:set_text(xyz)
						local n = utf8.len(xyz)
						self._searchbox.text:set_selection(n, n)
						self._searchbox:connect_search_input()
					end
				elseif browser[name] and type(browser[name]) == "string" or type(browser[name]) == "number" or type(browser[name]) == "boolean" then
					self._edit_value = name
					self._searchbox.text:set_text(tostring(self:digest_value_reveal(browser[name])))
					local n = utf8.len(tostring(self:digest_value_reveal(browser[name])))
					self._searchbox.text:set_selection(n, n)
					self._searchbox:connect_search_input()
				end
			elseif button == Idstring("1") and #self._table_path ~= 0 then
				table.remove(self._table_path, #self._table_path)
				self:open_tweak_table(self:table_to_browse())
			end
		end
	end
end

function TweakdataListGui:mouse_released(button, x, y)
	local result = TweakdataListGui.super.mouse_released(self, button, x, y)
	
	if alive(self._scroll) then
		return self._scroll:mouse_released(button, x, y)
	end
	
	return result
end


function TweakdataListGui:mouse_wheel_up(x, y)
	if alive(self._scroll) then
		self._scroll:scroll(x, y, 1)
	end
end

function TweakdataListGui:mouse_wheel_down(x, y)
	if alive(self._scroll) then
		self._scroll:scroll(x, y, -1)
	end
end

Hooks:Add("CoreMenuData.LoadDataMenu", "TweakdataListGui.CoreMenuData.LoadDataMenu", function(menu_id, menu)
	if menu_id == "start_menu" or menu_id == "pause_menu" then
		local new_node = {
			["_meta"] = "node",
			["name"] = "tweakdata_browser",
			["menu_components"] = "open_tweakdata_browser",
			["back_callback"] = "perform_blt_save",
			["no_item_parent"] = true,
			["no_menu_wrapper"] = true,
			["scene_state"] = menu_id == "start_menu" and "blackmarket_item" or nil,
			[1] = {
				["_meta"] = "default_item",
				["name"] = "back"
			}
		}
		table.insert(menu, new_node)
	end
end)

Hooks:Add("MenuManagerBuildCustomMenus", "lox_populate_categories", function(menu_manager, nodes)
	MenuHelper:AddMenuItem(nodes.main, "tweakdata_browser", "menu_tweakdata_browser", "", "divider_test2", "after")
	MenuHelper:AddMenuItem(nodes.pause, "tweakdata_browser", "menu_tweakdata_browser", "", "edit_game_settings", "after")
	MenuHelper:AddMenuItem(nodes.lobby, "tweakdata_browser", "menu_tweakdata_browser", "", "edit_game_settings", "after")
end)

MenuHelper:AddComponent("open_tweakdata_browser", TweakdataListGui)