extends Node2D

var database := PostgreSQLClient.new();
onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;
var isConnect = false;


func _init() -> void:
	pass
	
func _ready():
	var _error := database.connect("connection_established", self, "_isConnected") 
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _physics_process(_delta: float) -> void:
	database.poll();
	var buttons = $PanelContainer/MainPanel/ListUsers/ScrollContainer/NodeButton.get_children();
	for btn in buttons:
		if btn.pressed:
			$PanelContainer/MainPanel/Inputs/NameUser/Input.text = btn.text;
			
func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _exit_tree() -> void:
	database.close()

func loginDatabase() -> void:
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _isConnected():
	isConnect = true;
	var nameUser = executeQuery("SELECT usename FROM pg_catalog.pg_user ORDER BY usename ASC;");
	var res = getNameUser(nameUser);
	var sizeX = 150;
	var sizeY = 30;
	var incrSizeY = 0;
	for id in res:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(576+sizeX, 
			128+(sizeY*incrSizeY)));
		btn.set_size(Vector2(sizeX,sizeY));
		btn.text = res[id]['usename'];
		$PanelContainer/MainPanel/ListUsers/ScrollContainer/NodeButton.add_child(btn);
		btn.show();

func getNameUser(var datas):
	var dictResult = {}; 
	var index = 0;
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			var numberOfColumn = 0;
			var tempDictionnary = {};
			for value in row:	# List each data row
				var columnName = data.row_description[numberOfColumn]["field_name"];
				value = value.get_string_from_utf8();
				tempDictionnary.merge({columnName:value}, true);
				numberOfColumn += 1;
			dictResult.merge({index:tempDictionnary}, true);
			index += 1;
	return dictResult;


func getResult(var datas):
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			for value in row:	# List each data row
				return value;

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	return database.execute(_query);

func _on_Button_pressed():
	if(isConnect == false):
		return false;
	var nameUser = $PanelContainer/MainPanel/Inputs/NameUser/Input.text;
	var nameRole = $PanelContainer/MainPanel/Inputs/NameRole/Input.text;
	var queryPrinted = '';
	if nameRole.empty() && nameUser.empty():
		return 0;
	
	if !nameUser.empty():
		var queryUser = str("DROP USER IF EXISTS ", nameUser,";");
		var _execQuery = executeQuery(queryUser);
		print(_execQuery);
		queryPrinted = str(queryUser);
	
	if !nameRole.empty():
		var queryRole = str("DROP ROLE IF EXISTS ", nameRole,";");
		var _execQuery = executeQuery(queryRole);
		queryPrinted = str(queryPrinted, "\n", queryRole);
		
	$PanelContainer/MainPanel/Inputs/QueryUsed/Input.text = str(queryPrinted);
