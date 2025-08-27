[gd_resource type="Resource" script_class="RoomTemplate" load_steps=2 format=3 uid="uid://g2x3y4n5m6k7l"]

[ext_resource type="Script" path="res://scenes/rooms/custom_rooms/RoomTemplate.gd" id="1_0"]

[resource]
script = ExtResource("1_0")
template_name = "Training Room Template"
room_name = "Training Room"
room_description = "Train your guild members to improve their skills"
is_unlocked = true
has_top_bar = true
has_header = true
has_left_panel = true
has_right_panel = true
has_bottom_panel = true
header_label = "Train Your Guild Members"
left_panel_label = "Available Characters"
right_panel_label = "Training Information"
action_button_text = "Train Selected Character"
custom_properties = {
"character_list": "RoomContainer/MainContent/LeftPanel/LeftPanelScroll/LeftPanelVBox",
"training_info": "RoomContainer/MainContent/RightPanel/RightPanelScroll/RightPanelVBox",
"train_button": "RoomContainer/BottomPanel/ActionButton"
}
script_template_path = "res://scenes/rooms/custom_rooms/BaseRoomTemplate.gd"
theme_path = "res://theme.tres"

