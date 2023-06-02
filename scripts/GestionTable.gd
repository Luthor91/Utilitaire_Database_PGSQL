extends Node2D

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();
onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;
onready var buttonsTable = $PanelContainer/MainPanel/QueryPanel/NodeButtonTable/ScrollContainer/VBoxContainer;
onready var buttonsColumn = $PanelContainer/MainPanel/QueryPanel/NodeButtonColumn/ScrollContainer/VBoxContainer;
onready var nodeButtonsColumn = $PanelContainer/MainPanel/QueryPanel/NodeButtonColumn;
onready var nodeButtonsTable = $PanelContainer/MainPanel/QueryPanel/NodeButtonTable
var tableName = ''; # table selected
	
var _error = "";
var choice = "";

func _init() -> void:
	_error = database.connect("connection_established", self, "_query")
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _ready():
	choice = "table";
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE]);
	
func _physics_process(_delta: float) -> void:
	for btn in buttonsTable.get_children():
		if btn.pressed:
			if tableName == str(btn.text):
				continue;
			tableName = str(btn.text);
			$PanelContainer/MainPanel/QueryPanel/PanelRenameColumn/InputRenameColumn.text = str(btn.text);
			$PanelContainer/MainPanel/QueryPanel/PanelRenameTable/InputRenameTable.text = str(btn.text);
			showColumns();
			printButtonsColumn();
	for btn in buttonsColumn.get_children():
		if btn.pressed:
			var btnColumn = $PanelContainer/MainPanel/QueryPanel/PanelRenameColumn/InputRenameColumn;
			var content = btnColumn.text.split(',');
			btnColumn.text = str(content[0], ',', btn.text);
	database.poll()


func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _query():
	if choice == 'PK':
		reIndexPK();
	elif choice == 'FK':
		reCreateFK();
	elif choice == 'table':
		showTables();
		printButtonsTable();
	elif choice == 'column':
		showColumns();
		printButtonsColumn();
	elif choice == 'renametable':
		renameTable();
	elif choice == 'renamecolumn':
		renameColumn();


func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	if _query.ends_with(';'):
		return database.execute(_query);
	else:
		return database.execute(_query + ';');

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _exit_tree() -> void:
	database.close()
	
func reIndexPK():
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	var execTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') AND table_type = 'BASE TABLE' ORDER BY table_name;");
	var res1 = getResult(execTable);
	for table in res1:
		var local_tableName = str('"',res1[table]['table_name'],'"');
		var queryFirstPK = str("SELECT id FROM ", local_tableName,  " ORDER BY id ASC LIMIT 1;");
		var _execFirstPK = executeQuery(queryFirstPK);
		var resQueryFirstPK = getResult(_execFirstPK);
		if resQueryFirstPK.size() > 0:
			var gapId = resQueryFirstPK[0]['id'] -1;
			var queryUpdatePK = str("UPDATE ", local_tableName,  " SET id = id-", gapId, ";");
			var _execUpdatePK = executeQuery(queryUpdatePK);
			var queryFindPK = str("SELECT COUNT(1) FROM information_schema.table_constraints WHERE table_name='", local_tableName, "' AND constraint_name LIKE '%_pkey';");
			var _execFindPK = executeQuery(queryFindPK);
			$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res1[table]['table_name'], " => \n\t", resQueryFirstPK[0]['id'], " => 1\n");
		else:
			$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(local_tableName, " => ??\n");
		
func showTables():
	var nameTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name;");
	var res = getResult(nameTable);
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	for table in res:
		$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res[table]['table_name'], "\n");
		pass

func showColumns():
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", tableName, "' ORDER BY ordinal_position;");
	var execColumn = executeQuery(query);
	var res = getResult(execColumn);
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	for column in res:
		$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res[column]['column_name'], "\n");

func printButtonsColumn():
	if nodeButtonsColumn.visible == false:
		nodeButtonsColumn.show();
	var size = Vector2(256, 30);
	var incrSizeY = 0;
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", tableName, "' ORDER BY ordinal_position;");
	var nameColumn = executeQuery(query);
	var res = getResult(nameColumn);
	delete_children(buttonsColumn);
	for id in res:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(size.x, 
			-size.y+(size.y*incrSizeY)));
		btn.text = res[id]['column_name'];
		btn.set_size(size);
		buttonsColumn.add_child(btn);
		btn.show();
		$PanelContainer/MainPanel/QueryPanel/NodeButtonColumn/ScrollContainer.get_h_scrollbar().rect_scale.x = 0;

func printButtonsTable():
	if nodeButtonsTable.visible == false:
		nodeButtonsTable.show();
	var size = Vector2(200, 30);
	var incrSizeY = 0;
	var nameTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name ASC;");
	var res = getResult(nameTable);
	for id in res:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(size.x, 
			-size.y+(size.y*incrSizeY)));
		btn.text = res[id]['table_name'];
		btn.set_size(size);
		buttonsTable.add_child(btn);
		btn.show();
	$PanelContainer/MainPanel/QueryPanel/NodeButtonTable/ScrollContainer.get_h_scrollbar().rect_scale.x = 0;

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n);
		n.queue_free();

func renameTable():
	var input = $PanelContainer/MainPanel/QueryPanel/PanelRenameTable/InputRenameTable.text;
	var split = input.split(',');
	var oldNameTable = split[0];
	var newNameTable = split[1];
	var query = str('ALTER TABLE "', oldNameTable, '" RENAME TO "', newNameTable, '";');
	var _execColumn = executeQuery(query);

func renameColumn():
	var input = $PanelContainer/MainPanel/QueryPanel/PanelRenameColumn/InputRenameColumn.text;
	var split = input.split(',');
	var nameTable = split[0];
	var oldNameColumn = split[1];
	var newNameColumn = split[2];
	var query = str('ALTER TABLE "', nameTable, '" RENAME COLUMN "', oldNameColumn, '" TO "', newNameColumn, '";');
	var _execColumn = executeQuery(query);

func reCreateFK():
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	var execTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name;");
	var res1 = getResult(execTable);
	for table in res1:
		var local_tableName = res1[table]['table_name'];
		var queryColumn = str("SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name   = '", local_tableName, "' ORDER BY column_name;");
		var execColumn = executeQuery(queryColumn);
		var res2 = getResult(execColumn);
		for column in res2:
			var columnName = res2[column]['column_name'];
			if columnName.find('FK_', 0) == 0:
				var table1 = str('"',columnName.get_slice("_", 1),'"');
				var table2 = str('"',columnName.get_slice("_", 2),'"');
				columnName = str('"', columnName, '"');
				var queryFK = str("ALTER TABLE ", table1, " ADD CONSTRAINT ", columnName, " FOREIGN KEY (", columnName, ") REFERENCES ", table2, "(id);");
				var _execFK = executeQuery(queryFK);
		var queryFindFK = str("SELECT COUNT(1) FROM information_schema.table_constraints WHERE table_name='", res1[table]['table_name'], "' AND constraint_name LIKE 'FK_%';");
		var _execFindFK = executeQuery(queryFindFK);
		var resQueryFindFK = getResult(_execFindFK);
		$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res1[table]['table_name'], " => ", resQueryFindFK[0]['count'], "\n");

func _on_ButtonPK_pressed():
	choice = "PK";
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _on_ButtonFK_pressed():
	choice = "FK";
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

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

func _on_ButtonCopy_pressed():
	var txt = $PanelContainer/MainPanel/QueryResult/ResultQuery.text
	OS.set_clipboard(txt)

func _on_ButtonRenameTable_pressed():
	choice = "renametable";
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE]);

func _on_ButtonRenameColumn_pressed():
	choice = "renamecolumn";
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE]);


func _on_InputRenameTable_focus_entered():
	var output = str("Entrez :\n[AncienNomTable],[NouveauNomTable]\nExemple :\nOldName,NewName");
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = output;

func _on_InputRenameColumn_focus_entered():
	var output = str("Entrez :\n[NomTable],[AncienNomColonne],[NouveauNomColonne]\nExemple :\nNameTable,OldName,NewName");
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = output;
