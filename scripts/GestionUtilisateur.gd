extends Node2D

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();
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
	var buttonsUser = $PanelContainer/MainPanel/NodeButtonUser/Panel.get_children();
	var buttonsTable = $PanelContainer/MainPanel/NodeButtonTable/Panel.get_children();
	var _buttonsSchema = $PanelContainer/MainPanel/NodeButtonSchema/Panel.get_children();
	var buttonsGrant = $PanelContainer/MainPanel/NodeButtonGrant/Panel.get_children();
	var buttonsRevoke = $PanelContainer/MainPanel/NodeButtonRevoke/Panel.get_children();
	for btn in buttonsUser:
		if btn.pressed:
			if $PanelContainer/MainPanel/Modifier/NameUser/InputName.text != btn.text:
				$PanelContainer/MainPanel/Modifier/NameUser/InputName.text = btn.text;
				getPrivileges(btn.text);
	for btn in buttonsTable:
		if btn.pressed:
			if $PanelContainer/MainPanel/Modifier/Table/InputTable.text.empty():
				$PanelContainer/MainPanel/Modifier/Table/InputTable.text = str('"', btn.text, '"');
			else:
				if $PanelContainer/MainPanel/Modifier/Table/InputTable.text.find(btn.text) == -1:
					$PanelContainer/MainPanel/Modifier/Table/InputTable.text += str(', "',btn.text, '"');
	for btn in buttonsGrant:
		if btn.pressed:
			if $PanelContainer/MainPanel/Modifier/Grant/InputGrant.text.empty():
				$PanelContainer/MainPanel/Modifier/Grant/InputGrant.text = str(btn.text);
			else:
				if $PanelContainer/MainPanel/Modifier/Grant/InputGrant.text.find(btn.text) == -1:
					$PanelContainer/MainPanel/Modifier/Grant/InputGrant.text += str(', ',btn.text);
	for btn in buttonsRevoke:
		if btn.pressed:
			if $PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text.empty():
				$PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text = str(btn.text);
			else:
				if $PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text.find(btn.text) == -1:
					$PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text += str(', ',btn.text);
					
#	for btn in buttonsSchema:
#		if btn.pressed:
#			$PanelContainer/MainPanel/Modifier/Schema/InputSchema.text = btn.text;


	
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
	var res1 = getResult(nameUser);
	var nameTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name ASC;");
	var res2 = getResult(nameTable);
	var nameSchema = executeQuery("SELECT DISTINCT table_schema FROM information_schema.tables ORDER BY table_schema ASC");
	var res3 = getResult(nameSchema);
	var baseX = 0;
	var baseY = 0;
	var sizeX = 140;
	var sizeY = 20;
	var timeOverflowing = 0;
	var incrSizeY = 0;
	for id in res1:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(baseX+(timeOverflowing*sizeX), 
			(baseY-sizeY)+(sizeY*incrSizeY)));
		btn.set_size(Vector2(sizeX,sizeY));
		btn.text = res1[id]['usename'];
		$PanelContainer/MainPanel/NodeButtonUser/Panel.add_child(btn);
		btn.show();
		if $PanelContainer/MainPanel/NodeButtonUser/Panel.get_child_count()%21 == 0:
			incrSizeY = 0;
			timeOverflowing += 1;

	timeOverflowing = 0;
	incrSizeY = 0;
	for id in res2:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(baseX+(timeOverflowing*sizeX), 
			(baseY-sizeY)+(sizeY*incrSizeY)));
		btn.set_size(Vector2(sizeX,sizeY));
		btn.text = res2[id]['table_name'];
		$PanelContainer/MainPanel/NodeButtonTable/Panel.add_child(btn);
		btn.show();
		if $PanelContainer/MainPanel/NodeButtonTable/Panel.get_child_count()%21 == 0:
			incrSizeY = 0;
			timeOverflowing += 1;
	timeOverflowing = 0;
	incrSizeY = 0;
	for id in res3:
		incrSizeY += 1;
		var btn = Button.new();
		btn.set_position(
			Vector2(baseX+(timeOverflowing*sizeX), 
			(baseY-sizeY)+(sizeY*incrSizeY)));
		btn.set_size(Vector2(sizeX,sizeY));
		btn.text = res3[id]['table_schema'];
		$PanelContainer/MainPanel/NodeButtonSchema/Panel.add_child(btn);
		btn.show();
		if $PanelContainer/MainPanel/NodeButtonSchema/Panel.get_child_count()%21 == 0:
			incrSizeY = 0;
			timeOverflowing += 1;

func getResult(var datas):
	var dictResult = {}; 
	var index = 0;
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			var numberOfColumn = 0;
			var tempDictionnary = {};
			for value in row: # List each data row
				if typeof(value) == TYPE_RAW_ARRAY :
					value = value.get_string_from_utf8();
				var columnName = data.row_description[numberOfColumn]["field_name"];
				tempDictionnary.merge({columnName:value}, true);
				numberOfColumn += 1;
			dictResult.merge({index:tempDictionnary}, true);
			index += 1;
	return dictResult;
	
func getResultPrivileges(var datas):
	var dictResult = {}; 
	var index = 0;
	var columnRes = '';
	for data in datas: # Get result of query
		var privilege = [];
		var table = '';
		for row in data.data_row: # List each data column
			var numberOfColumn = 0;
			var tempDictionnary = {};
			
			var nbRow = 0;
			for value in row: # List each data row
				if typeof(value) == TYPE_RAW_ARRAY :
					value = value.get_string_from_utf8();
				var columnName = data.row_description[numberOfColumn]["field_name"];
				
				if columnName == 'table_name':
					if table != value:
						privilege = [];
					table = value;
				if columnName == 'privilege_type':
					if privilege.has(value) == false:
						privilege.append(value);
					nbRow +=1;
				tempDictionnary.merge({nbRow:privilege}, true);
				numberOfColumn += 1;
#			dictResult.merge({table:tempDictionnary}, true);
			dictResult[table] = privilege;
			index += 1;
	return dictResult;

func printPrivileges(var dict, var level = 0) -> void:
	if level == 0:
		$PanelContainer/MainPanel/Privileges/Label/TextEdit.text = "";
	for i in dict:
		var _element = range(0, level+1);
		if typeof(dict[i]) == TYPE_DICTIONARY:
			printPrivileges(dict[i], level + 1)
		else:
			$PanelContainer/MainPanel/Privileges/Label/TextEdit.text += str(dict[i])
		if (i != dict.keys().back()):
			$PanelContainer/MainPanel/Privileges/Label/TextEdit.text += "\n"

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	return database.execute(_query);

func getPrivileges(var nameRole):
	var queryRights = str("SELECT table_name, privilege_type FROM information_schema.role_table_grants WHERE grantee='",nameRole,"' AND table_schema NOT IN ('pg_catalog', 'information_schema', 'tiger', 'topology');");
	var _execRights = executeQuery(queryRights);
	var res = getResultPrivileges(_execRights);
	var resPrinted = niceJson.beautify_json(to_json(res), 2).replace('"', ' ');
	$PanelContainer/MainPanel/Privileges/Label/TextEdit.text = resPrinted;

func _on_InputName_mouse_entered():
	$PanelContainer/MainPanel/Modifier/NameUser/LabelInfo.visible = true;

func _on_InputName_mouse_exited():
	$PanelContainer/MainPanel/Modifier/NameUser/LabelInfo.visible = false;

func _on_InputPassword_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Password/Labelinfo.visible = true;

func _on_InputPassword_mouse_exited():
	$PanelContainer/MainPanel/Modifier/Password/Labelinfo.visible = false;

func _on_Grant_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Grant/LabelInfo.visible = true;

func _on_InputGrant_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Grant/LabelInfo.visible = true;

func _on_InputGrant_mouse_exited():
	$PanelContainer/MainPanel/Modifier/Grant/LabelInfo.visible = false;

func _on_InputRevoke_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Revoke/LabelInfo.visible = true;

func _on_InputRevoke_mouse_exited():
	$PanelContainer/MainPanel/Modifier/Revoke/LabelInfo.visible = false;

func _on_InputTable_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Table/LabelInfo.visible = true;

func _on_InputTable_mouse_exited():
	$PanelContainer/MainPanel/Modifier/Table/LabelInfo.visible = false;


func _on_InputSchema_mouse_entered():
	$PanelContainer/MainPanel/Modifier/Schema/LabelInfo.visible = true;


func _on_InputSchema_mouse_exited():
	$PanelContainer/MainPanel/Modifier/Schema/LabelInfo.visible = false;

func _on_ButtonExec_pressed():
	if(isConnect == false):
		return false;
	var nameUser = $PanelContainer/MainPanel/Modifier/NameUser/InputName.text;
	var password = $PanelContainer/MainPanel/Modifier/Password/InputPassword.text;
	var grant = $PanelContainer/MainPanel/Modifier/Grant/InputGrant.text;
	var revoke = $PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text;
#	var schema = $PanelContainer/MainPanel/Modifier/Schema/InputSchema.text;
	var table = $PanelContainer/MainPanel/Modifier/Table/InputTable.text;
	var strPrivileges = "";
	var oldName = '';
	var newName = '';
	var newPassword = '';
	
	if '=>' in nameUser:
		oldName = password.get_slice('=>', 0);
		newName = password.get_slice('=>', 1);
	else:
		oldName = nameUser;
	if "=>" in password:
		var _oldPassword = password.get_slice('=>', 0);
		newPassword = password.get_slice('=>', 1);
	else:
		newPassword = password;
#	if !schema.empty():
#		strPrivileges = str('SCHEMA ', schema);
#		table = '';
	if !table.empty():
		strPrivileges = str(table);
	var queryRevoke = str("REVOKE ", revoke, " ON ", strPrivileges ," FROM ", oldName, ";");
	var queryGrant = str("GRANT ", grant, " ON ", strPrivileges, " TO ", oldName, ";");
	var queryPassword = str("ALTER USER ", oldName," WITH PASSWORD '", newPassword,"';")
	var queryName = str("ALTER USER ", oldName," RENAME TO ", newName,";");
	if !revoke.empty():
		var _execRevoke = executeQuery(queryRevoke);
	if !grant.empty():
		var _execGrant = executeQuery(queryGrant);
	if !password.empty():
		var _execPassword = executeQuery(queryPassword);
	if !newName.empty():
		var _execName = executeQuery(queryName);

func _on_ButtonUser_pressed():
	$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonUser/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonUser/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();

func _on_ButtonTable_pressed():
	$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonTable/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonTable/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();

func _on_ButtonSchema_pressed():
	$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonSchema/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonSchema/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();

func _on_ButtonPrivileges_pressed():
	$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();

func _on_ButtonGrant_pressed():
	$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonGrant/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonGrant/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();

func _on_ButtonRevoke_pressed():
	$PanelContainer/MainPanel/NodeButtonTable/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonUser/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonSchema/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonListPrivileges/Panel.hide();
	$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();

	if $PanelContainer/MainPanel/NodeButtonRevoke/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonRevoke/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonRevoke/Panel.hide();


func _on_ButtonEmpty_pressed():
	$PanelContainer/MainPanel/Modifier/NameUser/InputName.text = '';
	$PanelContainer/MainPanel/Modifier/Password/InputPassword.text = '';
	$PanelContainer/MainPanel/Modifier/Grant/InputGrant.text = '';
	$PanelContainer/MainPanel/Modifier/Revoke/InputRevoke.text = '';
	$PanelContainer/MainPanel/Modifier/Table/InputTable.text = '';
	$PanelContainer/MainPanel/Modifier/Schema/InputSchema.text = '';
