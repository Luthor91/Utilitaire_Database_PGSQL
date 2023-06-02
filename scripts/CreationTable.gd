extends Node2D

var database := PostgreSQLClient.new();
onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

var _user_id = OS.get_unique_id()
var _error = "";
var choice = '';

func _init() -> void:
	_error = database.connect("connection_established", self, "_query")
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _ready():
	pass
 
func _physics_process(_delta: float) -> void:
	database.poll()
	
func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _query():
	var inputCreateTables = $PanelContainer/MainPanel/QueryPanel/InputQuery.text;
	if choice == 'tables':
		var json = JSON.parse(inputCreateTables);
		createAllTable(json.result);

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	if _query.ends_with(';'):
		return database.execute(_query);
	else:
		return database.execute(_query + ';');

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func createAllTable(var tabJson):
	var queryPrinted = '';
	for table in tabJson:
		var queryTable = '';
		var queryTablePrinted = '';
		for index in tabJson[table]:
			for column in tabJson[table][index]:
				queryTable = str(queryTable, ' ', tabJson[table][index][column]);
				queryTablePrinted = str(queryTablePrinted, ' ', tabJson[table][index][column]);
				if column == 'type':
					queryTable = str(queryTable, ',');
					queryTablePrinted = str(queryTablePrinted, ',\n');
		queryTable.erase(queryTable.length()-1, 1);
		var query = str('CREATE TABLE IF NOT EXISTS "', table, '" (', queryTable, ');');
		queryPrinted = str(queryPrinted, 'CREATE TABLE IF NOT EXISTS "', table, '" (\n', queryTablePrinted, ');', '\n\n');
		executeQuery(query);
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = queryPrinted;

func _on_ButtonExecute_pressed():
	choice = 'tables';
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _on_ButtonCopy_pressed():
	var txt = $PanelContainer/MainPanel/QueryResult/ResultQuery.text
	OS.set_clipboard(txt)

func _on_ButtonShowJSON_pressed():
	var labelInfo = $PanelContainer/MainPanel/QueryPanel/LabelInfo;
	if labelInfo.visible == true:
		labelInfo.visible = false;
	else:
		labelInfo.visible = true;
