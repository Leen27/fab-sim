extends Node2D

@onready var log_panel: ItemList = $Log/Panel/ItemList

# 配置
var config: Dictionary = {
	"factory_config": "res://config/factory.json",
	"recipe_config": "res://config/recipe.json",
	"eap_config": "res://config/eap_config.json",
	"mes_endpoint": "http://localhost:8080",
	"server_port": 8081
}

func _ready():
	log_panel.add_item("🔥 FabSim v0.1 启动！")

func _on_editor_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/editor.tscn")
