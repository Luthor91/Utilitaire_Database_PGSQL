extends Node2D

var database := PostgreSQLClient.new();

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;
var COLOR_TEXTE;
var COLOR_PANEL;
var dataJson = [];

var _error;

# Called when the node enters the scene tree for the first time.
func _ready():
	var baseX = 0;
	var baseY = 0;
	var sizeX = 140;
	var sizeY = 20;
	var timeOverflowing = 0;
	var incrSizeY = 0;
	$PanelContainer/MainPanel/LabelInfoConn.text = str("BDD : %s\nUser : %s\nPWD : ***** \nServer : %s\nPort : %d"
	% [DATABASE, USER, HOST, PORT]);
	_error = database.connect("connection_established", self, "_connected");
	_error = database.connect("authentication_error", self, "_authentication_error");
	_error = database.connect("connection_closed", self, "_close");
	#Connection to the database
	var file = Globals.rFile("Databases.txt");
	if file.empty():
		Globals.wFile('', "Databases.txt");
		file = '';
	var lines = file.split("\n");
	for line in lines:
		var user = line.get_slice(":", 1).substr(2, line.get_slice(":", 1).length());
		var db = line.get_slice("/", 3);
		var port = line.get_slice(":", 3).get_slice("/", 0);
		var server = line.get_slice("@", 1).get_slice(":", 0);
		if line.empty():
			continue;
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(baseX+(timeOverflowing*sizeX), 
			(baseY-sizeY)+(sizeY*incrSizeY)));
		btn.set_size(Vector2(sizeX,sizeY));
		btn.text = str(db, "-", user, "-", server, "-", port);
		$PanelContainer/MainPanel/Historic/Panel.add_child(btn);
		btn.show();
		if $PanelContainer/MainPanel/Historic/Panel.get_child_count()%21 == 0:
			break;
#			incrSizeY = 0;
#			timeOverflowing += 1;

func _physics_process(_delta: float) -> void:
	database.poll()
	var buttonsConnect = $PanelContainer/MainPanel/Historic/Panel.get_children();
	for btn in buttonsConnect:
		if btn.pressed:
			$PanelContainer/MainPanel/Inputs/Server/Input.text = btn.text.get_slice("-", 2);
			$PanelContainer/MainPanel/Inputs/DatabaseName/Input.text = btn.text.get_slice("-", 0);
			$PanelContainer/MainPanel/Inputs/Port/Input.text = btn.text.get_slice("-", 3);
			$PanelContainer/MainPanel/Inputs/Username/Input.text = btn.text.get_slice("-", 1);
			
func _connected():
	Globals.USER = USER;
	Globals.PASSWORD = PASSWORD;
	Globals.HOST = HOST;
	Globals.DATABASE = DATABASE;
	Globals.PORT = PORT;
	Globals.isConn = true;
	Globals.rwFile("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE], "Databases.txt");
	database.close();
	var _changeScene = get_tree().change_scene("res://scene/Database.tscn");

func get_inputs():
	USER = $PanelContainer/MainPanel/Inputs/Username/Input.text;
	PASSWORD = $PanelContainer/MainPanel/Inputs/Password/Input.text;
	HOST = $PanelContainer/MainPanel/Inputs/Server/Input.text;
	DATABASE = $PanelContainer/MainPanel/Inputs/DatabaseName/Input.text;
	PORT = int($PanelContainer/MainPanel/Inputs/Port/Input.text);
	

func get_defaultLogs():
	var file = Globals.rFile("DefaultLogs.txt");
	if file.empty():
		Globals.wFile("postgres,postgres,postgres,127.0.0.1,5432", "DefaultLogs.txt");
		file = Globals.rFile("DefaultLogs.txt");
	var args = [];
	args = file.split(',', 0);
	DATABASE = str(args[0]);
	USER = str(args[1]);
	PASSWORD = str(args[2]);
	HOST = str(args[3]);
	PORT = int(args[4]);

func _on_Button_pressed():
	get_inputs()
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.show();
	$PanelContainer/MainPanel/Inputs/Error.text = str("Erreur arguments de connexion invalide.\nOu alors service Postgres désactivé.");

func _on_ButtonTry_pressed():
	get_defaultLogs();
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.show();
	$PanelContainer/MainPanel/Inputs/Error.text = str("Erreur arguments de connexion invalide.\nOu alors service Postgres désactivé.");

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure);

func _exit_tree() -> void:
	database.close();

func _on_ButtonTry_mouse_entered():
	$PanelContainer/MainPanel/LabelInfoConn.show();


func _on_ButtonTry_mouse_exited():
	$PanelContainer/MainPanel/LabelInfoConn.hide();
