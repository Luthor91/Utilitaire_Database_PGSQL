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
	_error = database.connect("connection_established", self, "_query") 
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _physics_process(_delta: float) -> void:
	database.poll()

func _query():
	pass

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _on_Btn1_pressed():
	OS.alert('test');

func _on_Btn2_pressed():
	var _output = [];
	var _res = OS.execute('find', ['/s', '/b', 'C:\\pgadmin'], false);
#	OS.execute("cmd", [''], false);

func _on_Btn3_pressed():
#	Fonctionne, besoins de droit d'admin
	var _res = OS.execute('cmd.exe', ['/c', 'net start postgresql-x64-14'], false);
