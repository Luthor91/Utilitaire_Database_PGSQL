extends Node2D

var database := PostgreSQLClient.new();

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

var _error = '';

func _init() -> void:
	pass
	
func _ready():
	var content;
	var args;
	
	$Control/ColorPanel/ColorPicker.self_modulate = Color(1,1,1,1);
	$Control/ColorText/ColorPicker.self_modulate = Color(1,1,1,1);
	
	content = Globals.rFile("ColorPanel.txt");
	if content == '':
		$Control/ColorPanel/ColorPicker.color = Color(1,1,1,1);
	else:
		args = content.split(',', 0);
		$Control/ColorPanel/ColorPicker.color = Color(args[0],args[1],args[2],1);
#	content = loadFile("res://Logs/ColorText.txt");
#	args = content.split(',', 0);
#	$Control/ColorText/ColorPicker.color = Color(args[0],args[1],args[2],1);
	_error = database.connect("connection_established", self, "_query") 
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _physics_process(_delta: float) -> void:
	database.poll()

func _query():
	Globals.wFile("%s,%s,%s,%s,%d" % [DATABASE, USER, PASSWORD, HOST, PORT], "DefaultLogs.txt");

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _on_Button_pressed():
	DATABASE = $PanelContainer/MainPanel/Inputs/DefaultAccount/DatabaseName/Input.text;
	USER = $PanelContainer/MainPanel/Inputs/DefaultAccount/UserName/Input.text;
	PASSWORD = $PanelContainer/MainPanel/Inputs/DefaultAccount/Password/Input.text;
	HOST = $PanelContainer/MainPanel/Inputs/DefaultAccount/Server/Input.text;
	PORT = int($PanelContainer/MainPanel/Inputs/DefaultAccount/Port/Input.text);
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])


func _on_ButtonDefaultAccount_pressed():
	$PanelContainer/MainPanel/Inputs/WindowSize.hide();
	
	if $PanelContainer/MainPanel/Inputs/DefaultAccount.visible == false:
		$PanelContainer/MainPanel/Inputs/DefaultAccount.show();
	else:
		$PanelContainer/MainPanel/Inputs/DefaultAccount.hide();


func _on_ButtonColorText_pressed():
	$Control/ColorPanel.hide();
	pass
	
	var color = $Control/ColorText/ColorPicker.get_pick_color();
	if $Control/ColorText.visible == false:
		$Control/ColorText.show();
	else:
		$Control/ColorText.hide();
	color[3] = 1;
	Globals.wFile(color, "ColorText.txt");


func _on_ButtonColorPanel_pressed():
	$Control/ColorText.hide();
	
	var color = $Control/ColorPanel/ColorPicker.get_pick_color();
	if color.get_luminance() < 0.90:
		color.v = 0.90;
#		color = Color(1,1,1,1);
#		color.lightened(0.2);
	if $Control/ColorPanel.visible == false:
		$Control/ColorPanel.show();
	else:
		$Control/ColorPanel.hide();
		var _dump = get_tree().change_scene("res://scene/Options.tscn");
	color[3] = 1;
	Globals.wFile(color, "ColorPanel.txt");


func _on_ButtonWindowSize_pressed():
	$PanelContainer/MainPanel/Inputs/DefaultAccount.hide();
	
	if $PanelContainer/MainPanel/Inputs/WindowSize.visible == false:
		$PanelContainer/MainPanel/Inputs/WindowSize.show();
	else:
		$PanelContainer/MainPanel/Inputs/WindowSize.hide();

func _on_ButtonSize1_pressed():
	pass

func _on_ButtonSize2_pressed():
	pass


func _on_ButtonSize3_pressed():
	OS.window_size = Vector2(1024,600);
	Globals.wFile('1024, 600', 'ScreenSize.txt');
#	var _dump = get_tree().change_scene("res://scene/Options.tscn");


func _on_ButtonSize4_pressed():
	OS.window_size = Vector2(900,528);
	Globals.wFile('900, 528', 'ScreenSize.txt');
#	var _dump = get_tree().change_scene("res://scene/Options.tscn");


func _on_ButtonFindPGSQL_pressed():
	OS.alert('test');
	pass # Replace with function body.
