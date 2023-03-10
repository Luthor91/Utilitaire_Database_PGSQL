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
	database.poll()
	var buttonsPrivileges = $PanelContainer/MainPanel/NodeButtonGrant/Panel.get_children();
	for btn in buttonsPrivileges:
		if btn.pressed:
			var output = $PanelContainer/MainPanel/Inputs/Rights/Input;
			if output.text.empty():
				output.text = str(btn.text);
			else:
				if output.text.find(btn.text) == -1:
					output.text += str(', ',btn.text);
				else:
					output.text.replace(str(btn.text), '');
			if output.text.ends_with(','):
				output.text = output.text.substr(0, output.text.length()-2);


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
	
func getResult(var datas):
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			for value in row:	# List each data row
				return value;

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	var _dump = database.execute(_query);

func _on_Input2_mouse_entered():
	$PanelContainer/MainPanel/Inputs/Rights/Infos.visible = true;

func _on_Input2_mouse_exited():
	$PanelContainer/MainPanel/Inputs/Rights/Infos.visible = false;

func _on_Button2_pressed():
	if(isConnect == false):
		return false;
	var nameRole = $PanelContainer/MainPanel/Inputs/NameRole/Input.text;
	var password = $PanelContainer/MainPanel/Inputs/Password/Input.text;
	var rights = $PanelContainer/MainPanel/Inputs/Rights/Input.text;
	var strPWD = '';
	var strRole = '';
	var strRights = '';
	
	if !nameRole.empty():
		strRole = str("", nameRole, " ");
	else:
		return 0;
		
	if !rights.empty():
		if rights.ends_with(','):
			rights = rights.substr(1, rights.length()-2);
		strRights = str("", rights, " ");
	if !password.empty():
		if ":" in password:
			var pwd = password.get_slice(':', 0);
			var datVal = password.get_slice(':', 1);
			strPWD = str("LOGIN PASSWORD '", pwd, "' VALID UNTIL '", datVal, "' ");
		else:
			strPWD = str("LOGIN PASSWORD '", password, "'");
	var queryRole = str("CREATE ROLE ", strRole, strRights, strPWD, ";");
	print("query : X", queryRole,"X");
	var queryRolePrinted = str("CREATE ROLE ", strRole, "\n", strRights, "\n", strPWD, ";");
	var _execQuery = executeQuery(queryRole);
#	var _stmt = getResult(execQuery);
	$PanelContainer/MainPanel/Inputs/QueryUsed/Input.text = str(queryRolePrinted);

func _on_Input_mouse_entered():
	$PanelContainer/MainPanel/Inputs/Password/Infos.visible = true;

func _on_Input_mouse_exited():
	$PanelContainer/MainPanel/Inputs/Password/Infos.visible = false;


func _on_Button_pressed():
	if $PanelContainer/MainPanel/NodeButtonGrant/Panel.visible == false:
		$PanelContainer/MainPanel/NodeButtonGrant/Panel.show();
	else:
		$PanelContainer/MainPanel/NodeButtonGrant/Panel.hide();
