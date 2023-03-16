extends Node2D

var database := PostgreSQLClient.new();

############################################
#	Variables de connexion à la base de données par défaut
#

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

var timeout = false;
var maxSize = Vector2.ZERO;
var _error;

############################################
#	Méthodes d'initialisation de données
#


func _ready():
	var size = Vector2(250, 30);
	maxSize = size;
	var timeOverflowing = 0;
	var incrSizeY = 0;
	var nodeHistoric = $PanelContainer/MainPanel/TabContainer/TabHistorique/Historic/ScrollHistoric/VBoxContainer;
	$PanelContainer/MainPanel/LabelInfoConn.text = str("BDD : %s\nUser : %s\nPWD : ***** \nServer : %s\nPort : %d"
	% [DATABASE, USER, HOST, PORT]);
	_error = database.connect("connection_established", self, "_connected");
	_error = database.connect("authentication_error", self, "_authentication_error");
	_error = database.connect("connection_closed", self, "_close");
	var file = Globals.rFile("Databases.txt");
	if file.empty():
		Globals.wFile('', "Databases.txt");
		file = '';
	var lines = file.split("\n");
	
	############################################
	#	Création du premier onglet "Historique"
	#
	
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
			Vector2(timeOverflowing*size.x, 
			-size.y+(size.y*incrSizeY)));
		btn.set_size(size);
		btn.text = str(db, "-", user, "-", server, "-", port);
		nodeHistoric.add_child(btn);
		btn.show();
		if btn.get_size().x > maxSize.x:
			maxSize.x = btn.get_size().x;
		maxSize.y += btn.get_size().y;
	$PanelContainer/MainPanel/TabContainer.rect_size = maxSize;
	$PanelContainer/MainPanel/TabContainer/Tabs.rect_size = Vector2(352, 292);
	
	$PanelContainer/MainPanel/TabContainer/TabHistorique/Historic/ScrollHistoric.rect_size = maxSize;
	$PanelContainer/MainPanel/TabContainer/TabHistorique/Historic/ScrollHistoric.get_h_scrollbar().rect_scale.x = 0;

############################################
#	Boucle infini
#

func _physics_process(_delta: float) -> void:
	database.poll()
	var buttonsConnect = $PanelContainer/MainPanel/TabContainer/TabHistorique/Historic/ScrollHistoric/VBoxContainer.get_children();
	for btn in buttonsConnect:
		if btn.pressed:
			$PanelContainer/MainPanel/Inputs/Server/Input.text = btn.text.get_slice("-", 2);
			$PanelContainer/MainPanel/Inputs/DatabaseName/Input.text = btn.text.get_slice("-", 0);
			$PanelContainer/MainPanel/Inputs/Port/Input.text = btn.text.get_slice("-", 3);
			$PanelContainer/MainPanel/Inputs/Username/Input.text = btn.text.get_slice("-", 1);

############################################
#	Méthodes des signaux de la database 
#

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
	var _changeScene = get_tree().change_scene("res://scene/RequeteFormulaire.tscn");

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure);

func _exit_tree() -> void:
	database.close();

############################################
#	Méthodes permettant d'avoir des données
#

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

############################################
#	Exécution de la connexion
#

func _on_Button_pressed():
	get_inputs()
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.text = str("Démarrage des services nécessaires\nTemps d'attente estimé :\nentre 2 à 5secondes");
	$PanelContainer/MainPanel/Inputs/Error.show();
	$TimerConn.start(2);
	yield($TimerConn, "timeout");
	var command = str('net start postgresql-x64-', Globals.VERSION);
	var _res = OS.execute('cmd.exe', ['/c', command], true);
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.text = str('Erreur arguments de connexion invalide.\nOu alors service Postgres désactivé.');
	$PanelContainer/MainPanel/Inputs/Error.show();

func _on_ButtonTry_pressed():
	get_defaultLogs();
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.text = str("Démarrage des services nécessaires\nTemps d'attente estimé :\nentre 2 à 5 secondes");
	$PanelContainer/MainPanel/Inputs/Error.show();
	$TimerConn.start(2);
	yield($TimerConn, "timeout");
	var command = str('net start postgresql-x64-', Globals.VERSION);
	var _res = OS.execute('cmd.exe', ['/c', command], true);
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	$PanelContainer/MainPanel/Inputs/Error.text = str('Erreur arguments de connexion invalide.\nOu alors service Postgres désactivé.');
	$PanelContainer/MainPanel/Inputs/Error.show();

############################################
#	Gestion de l'affichage de la database enregistré
#

func _on_ButtonTry_mouse_entered():
	$PanelContainer/MainPanel/LabelInfoConn.show();

func _on_ButtonTry_mouse_exited():
	$PanelContainer/MainPanel/LabelInfoConn.hide();

############################################
#	Gestion de la taille des onglets
#

func _on_TabContainer_tab_selected(tab):
	match tab:
		0:
			$PanelContainer/MainPanel/TabContainer.rect_size = maxSize;
			$PanelContainer/MainPanel/TabContainer/Tabs.rect_size = maxSize;
		1:
			$PanelContainer/MainPanel/TabContainer.rect_size = Vector2(360, 328);
			$PanelContainer/MainPanel/TabContainer/Tabs.rect_size = Vector2(352, 292);
	
