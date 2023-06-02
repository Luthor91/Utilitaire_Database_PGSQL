extends Node2D

var database := PostgreSQLClient.new();

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;
var select = '';
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
	if select == 'exportCSV':
		var execTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') AND table_type = 'BASE TABLE' ORDER BY table_name;");
		var res = getResult(execTable);
		var filePathFinal = str(OS.get_user_data_dir(), '/CSV/');
		var filePathSplit = filePathFinal.split('/');
		var filePath = str(filePathSplit[0], '/', filePathSplit[1], '/Public/');
		var dir = Directory.new();
		dir.open("user://");
		dir.make_dir("CSV");
		for table in res:
			var tableName = str(res[table]['table_name']);
			var fileName = str(tableName, '.csv');
			var _path = str("'", filePathFinal, fileName, "'");
			var userPath = str("'", filePath, fileName, "'");
#			Get  SYSTEM_DIR_DOCUMENTS  mis en commentaire à cause de problèmes de droits d'accès
#			var pathDoc = OS.get_system_dir(2);
#			var pathTest = str("'", pathDoc, fileName, "'");
#			Globals.wFile('', str('CSV/', fileName));
			var query = str('COPY "', tableName, '" TO ', userPath, ' CSV HEADER;');
			print(query);
			var _execCOPY = executeQuery(query);


func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	if _query.ends_with(';'):
		return database.execute(_query);
	else:
		return database.execute(_query + ';');

func getResult(var datas):
	var dictResult = {}; 
	var index = 0;
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			var numberOfColumn = 0;
			var tempDictionnary = {};
			for value in row:	# List each data row
				var columnName = data.row_description[numberOfColumn]["field_name"];
				if typeof(value) == TYPE_RAW_ARRAY :
					value = value.get_string_from_utf8();
				tempDictionnary.merge({columnName:value}, true);
				numberOfColumn += 1;
			dictResult.merge({index:tempDictionnary}, true);
			index += 1;
	return dictResult;

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func selector(var choice):
	select = choice;
	if choice == 'exportBackup':
#		visibilityExportFile();
		pass
	elif choice == 'exportCSV':
#		visibilityExportFile();
		exportCSV();
	elif choice == 'importCSV':
#		visibilityImportFile();
		pass
	elif choice == 'importBackup':
#		visibilityImportFile();
		pass
	print(choice);

func exportCSV():
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func visibilityImportFile():
	$PanelContainer/MainPanel/Import.rect_size = Vector2(464, 352);
	$PanelContainer/MainPanel/Import.rect_position = Vector2(441, 81);
	if $PanelContainer/MainPanel/Import.visible == true:
		$PanelContainer/MainPanel/Import.hide();
	else:
		$PanelContainer/MainPanel/Import.show();
		
func visibilityExportFile():
	$PanelContainer/MainPanel/Export.rect_size = Vector2(464, 352);
	$PanelContainer/MainPanel/Export.rect_position = Vector2(441, 81);
	if $PanelContainer/MainPanel/Export.visible == true:
		$PanelContainer/MainPanel/Export.hide();
	else:
		$PanelContainer/MainPanel/Export.show();

func _on_ButtonExportCSV_pressed():
	selector("exportCSV");

func _on_ButtonExportBackup_pressed():
	selector("export");

func _on_ButtonImportCSV_pressed():
	selector("importCSV");

func _on_ButtonImportBackup_pressed():
	selector("importBackup");

func _on_FileDialog_confirmed():
	var fileName = $PanelContainer/MainPanel/Import.current_file;
	var filePath = $PanelContainer/MainPanel/Import.current_path;
	print("filename : ", fileName);
	print("filepath : ", filePath);
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])
	$PanelContainer/MainPanel/Import.hide();


func _on_ButtonExportCSV_mouse_entered():
	$PanelContainer/MainPanel/Inputs/PanelExport/hint.show();


func _on_ButtonExportCSV_mouse_exited():
	$PanelContainer/MainPanel/Inputs/PanelExport/hint.hide();
