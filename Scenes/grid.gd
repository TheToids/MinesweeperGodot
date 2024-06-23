#
#
# setup user custom board setup
# 
#

extends Control
var time_lapse = Globals.time_lapse
var mines = Globals.mines
var grid_sides = Globals.grid_sides
var cell_size = Globals.cell_size #change to dynamically adjust to int from float
var grid_size = Globals.grid_size
var cell_positions =  Globals.cell_positions
var mine_positions =  Globals.mine_positions
var cell_sprites =  Globals.cell_sprites
var grey_cell =  Globals.grey_cell
var green_cell =  Globals.green_cell
var flag_cell =  Globals.flag_cell
var death_cell =  Globals.death_cell
#var Header = Globals.Header
var time_lapse_label = Globals.time_lapse_label

func _init():
	pass

func _ready():
	#get_parent().call_deferred("add_child", $"../Header")
	self.size = grid_size #default
	self.position = (get_parent().get_viewport_rect().size / 2) - (self.size / 2) #default
	Globals.mine_text_field.text_submitted.connect(_on_LineEdit_text_submitted)
	chooseMines()
	popGrid()
	#Globals.timer.wait_time = 1.0
	#Globals.timer.one_shot = false
	#Globals.timer.timeout.connect(_on_timer_timeout)
	#$"../Header".add_child(Globals.timer)
	#Globals.timer.start()
	
	#var style_box = StyleBoxFlat.new()
	#style_box.border_width_left = 1
	#style_box.border_width_top = 1
	#style_box.border_width_right = 1
	#style_box.border_width_bottom = 1
	#style_box.border_color = Color(1, 0, 0, 1)  # Red color
	#self.set("custom_styles/default", style_box)
	

func _on_timer_timeout():
	pass
	#Globals.time_lapse_label.text = str(Globals.timer.time_left)

func _on_LineEdit_text_submitted(event): #breaks code
	chooseMines()
	popGrid()
	#print(Globals.mine_positions)

func format_time(time_in_seconds):
	var hours = int(time_in_seconds / 3600)
	var minutes = int((time_in_seconds % 3600) / 60)
	var seconds = int(time_in_seconds % 60)
	return "%sh %sm %ss" % [hours, minutes, seconds]

func _process(delta):
	time_lapse += delta
	time_lapse_label.text = format_time(int(time_lapse))
	#var time_seconds = int(time_lapse)
	#if time_seconds > 3600:
		#var hours = time_seconds / 3600
		#var minutes = (time_seconds % 3600) / 60
		#var seconds = time_seconds % 60
		#time_seconds = str(hours) + "h" + str(minutes) + "m" + str(seconds) + "s"
	#elif time_seconds > 60:
		#var minutes = time_seconds / 60
		#var seconds = time_seconds % 60
		#time_seconds = str(minutes) + "m" + str(seconds) + "s"
	#else:
		#time_seconds = str(time_seconds) + "s"

	Globals.flag_count_label.text = str(Globals.flag_count)
	
	if Input.is_action_just_pressed("click"):
		print(Globals.mines)
		var mouse_position = get_local_mouse_position()
		for sprite in cell_sprites.keys():
			var cell_rect = Rect2(sprite.position, cell_size)
			if cell_rect.has_point(mouse_position):
				if cell_sprites[sprite]["mine"] == true:
					sprite.texture = death_cell 
				elif sprite.texture == grey_cell or cell_sprites[sprite]["mine"] == false:
					clearNeighbors(sprite)
				break
	
	if Input.is_action_just_pressed("rightclick"):
		var mouse_position = get_local_mouse_position()
		for sprite in cell_sprites.keys():
			var cell_position = sprite.position
			var cell_rect = Rect2(cell_position - sprite.offset, cell_size)
			if cell_rect.has_point(mouse_position) and sprite.texture != death_cell:
				if sprite.texture == flag_cell: 
					if sprite.get_child(0): 
						sprite.texture = green_cell
						sprite.get_child(0).visible = true
						Globals.flag_count -= 1
						break
					sprite.texture = grey_cell
					Globals.flag_count -= 1
				else: 
					sprite.texture = flag_cell
					if sprite.get_child(0): 
						if sprite.get_child(1): sprite.get_child(1).visible = false
						sprite.get_child(0).visible = false
					Globals.flag_count += 1
				break		
				
func chooseMines():
	clear()
	#move this for loop to popgrid?
	for cell_x in range(Globals.grid_sides.x):
		for cell_y in range(Globals.grid_sides.y):
			Globals.cell_positions.append(Vector2(cell_x, cell_y) * Globals.cell_size)
	while Globals.mines > 0:
		var mine_loc = Globals.cell_positions[randi_range(0, len(Globals.cell_positions) - 1)]
		#if Globals.mine_positons.has(mine_loc):
		if mine_loc in Globals.mine_positions:
			continue
		Globals.mine_positions.append(mine_loc)
		Globals.mines -= 1
	

func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	Globals.mine_positions.clear()
	Globals.cell_positions.clear()
	cell_sprites.clear()

func popGrid():
	################################################
	Globals.timer.stop()
	Globals.timer.start()
	for y in range(grid_sides.y):
		for x in range(grid_sides.x):
			var sprite = Sprite2D.new()
			sprite.centered = false
			sprite.texture = grey_cell
			#sprite.scale = Vector2(4, 4)
			sprite.scale = Globals.cell_size / sprite.get_rect().size
			sprite.position += Vector2(x, y) * cell_size 
			self.add_child(sprite)
			cell_sprites[sprite] = {}
			cell_sprites[sprite]["number"] = 0
			if sprite.position in mine_positions:
				cell_sprites[sprite]["mine"] = true 
				
			else:
				cell_sprites[sprite]["mine"] = false #make a nested dictionary ?
	buildMineNeighbors()
	#print(self.get_children())
	#print(mine_positions)

func buildMineNeighbors():
	var directions = [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
	for mine in mine_positions:
		for direction in directions:
			var neighbor_sprite = get_node_at_position((mine / cell_size + direction) * cell_size)
			if neighbor_sprite != null:
				cell_sprites[neighbor_sprite]["number"] += 1
				#print(cell_sprites[neighbor_sprite]["number"])
	#print(cell_sprites)
	
func clearNeighbors(sprite):
	sprite.texture = green_cell
	sprite.add_child(setupLabelForCell(str(cell_sprites[sprite]["number"])))
	var directions = [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
	for direction in directions:
		var neighbor_sprite = get_node_at_position(((sprite.position / cell_size) + direction) * cell_size)
		if neighbor_sprite != null and cell_sprites[neighbor_sprite]["mine"] == false and (neighbor_sprite.texture == grey_cell or neighbor_sprite.texture == flag_cell):
			if neighbor_sprite.texture == flag_cell: Globals.flag_count -= 1
			neighbor_sprite.texture = green_cell
			neighbor_sprite.add_child(setupLabelForCell(str(cell_sprites[neighbor_sprite]["number"])))
			if cell_sprites[neighbor_sprite]["number"] == 0:
				clearNeighbors(neighbor_sprite)
					
func setupLabelForCell(text):
	var cell_settings = LabelSettings.new()
	cell_settings.set_font_color("white")
	cell_settings.set_font_size(32)
	cell_settings.set_outline_color("black")
	cell_settings.set_outline_size(6)
	var label = Label.new()
	label.set_custom_minimum_size(cell_size)
	label.scale = Vector2(0.25, 0.25)
	label.label_settings = cell_settings
	label.horizontal_alignment = 1
	label.vertical_alignment = 1
	label.text = text
	return label
	
func get_node_at_position(pos):
	for sprite in cell_sprites.keys():
		if sprite.position == pos:
			return sprite
	return null


