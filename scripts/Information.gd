extends Node2D

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

func _init() -> void:
	pass
	
func _ready():
	var _error := database.connect("connection_established", self, "fillInput") 
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _physics_process(_delta: float) -> void:
	database.poll()

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _exit_tree() -> void:
	database.close()

func loginDatabase() -> void:
	var _dump = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func fillInput():
	var execVersion = executeQuery("SELECT version();");
	var versionDatabase = getResult(execVersion);
	versionDatabase = versionDatabase.substr(0, versionDatabase.find(','));
	$PanelContainer/MainPanel/Inputs/Version/InputVersion.text = str(versionDatabase);
		
	var execSize = executeQuery("SELECT pg_database_size('"+DATABASE+"');");
	var sizeDatabase = getResult(execSize);
	$PanelContainer/MainPanel/Inputs/Taille/InputTaille.text = str(String.humanize_size(sizeDatabase));
	
	var execTable = executeQuery("SELECT count(*) FROM information_schema.tables;");
	var tableDatabase = getResult(execTable);
	var execTablePublic = executeQuery("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';");
	var tablePublicDatabase = getResult(execTablePublic);
	$PanelContainer/MainPanel/Inputs/Table/InputTable.text = "Public : " + str(tablePublicDatabase) + " - Total : " + str(tableDatabase);
	
	var execUser = executeQuery("SELECT count(*) FROM pg_catalog.pg_user;");
	var userDatabase = getResult(execUser);
	$PanelContainer/MainPanel/Inputs/Compte/InputCompte.text = str(userDatabase);
	
	var execExtension = executeQuery("SELECT count(*) FROM pg_extension;");
	var extensionDatabase = getResult(execExtension);
	$PanelContainer/MainPanel/Inputs/Extension/InputExtension.text = str(extensionDatabase);
	

func isInDict(var dict, var needle):
	for row in dict:
		for value in row:
			if typeof(value) == TYPE_RAW_ARRAY:
				value = value.get_string_from_utf8();
			if str(needle) in str(row):
				print("needle : ", str(needle), " row : ", str(row));
				return true;
	return false;

func getResult(var datas):
	var dictResult = {}; 
	var index = 0;
	var IsInColumn = false;
	var IsInValue = false;
	for data in datas: # Get result of query
		for row in data.data_row: # List each data column
			#Boucle sur chaque enregistrement
			var numberOfColumn = 0;
			var tempDictionnary = {};
			var allKeys = data.row_description[numberOfColumn].keys();
#			FAIRE FILTRE SUR DONNEE ET AFFICHER TOUT L'ENREGISTREMENT
#			if not $PanelContainer/MainPanel/Filtre/InputFiltreRow.text.empty():
#				print($PanelContainer/MainPanel/Filtre/InputFiltreRow.text, " || is in || ", value);
#				if not $PanelContainer/MainPanel/Filtre/InputFiltreRow.text in str(value):
#					continue;
			for value in row:	# List each data row
				#Boucle sur chaque colonnes
				var columnName = data.row_description[numberOfColumn]["field_name"];
				if not $PanelContainer/MainPanel/Filtre/InputFiltreColumn.text.empty():
					if not $PanelContainer/MainPanel/Filtre/InputFiltreColumn.text in str(columnName):
						continue;
				if row.size() == 1:
					return value;
				if typeof(value) == TYPE_RAW_ARRAY :
					value = value.get_string_from_utf8();

				tempDictionnary.merge({columnName:value}, true);
				numberOfColumn += 1;
			dictResult.merge({index:tempDictionnary}, true);
			index += 1;
	return dictResult;

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	return database.execute(_query);

func _on_InputExtension_focus_entered():
	var exec = executeQuery("SELECT * FROM pg_extension;");
	var res = getResult(exec);
	var resPrinted = niceJson.beautify_json(to_json(res), 2).replace('"', ' ');
	$PanelContainer/MainPanel/Outputs/output.text = str(resPrinted);
	$PanelContainer/MainPanel/Outputs.show();

func _on_InputExtension_focus_exited():
	$PanelContainer/MainPanel/Outputs.hide();

func _on_InputCompte_focus_entered():
	var exec = executeQuery("SELECT * FROM pg_catalog.pg_user");
	var res = getResult(exec);
	var resPrinted = niceJson.beautify_json(to_json(res), 2).replace('"', ' ');
	$PanelContainer/MainPanel/Outputs/output.text = str(resPrinted);
	$PanelContainer/MainPanel/Outputs.show();

func _on_InputCompte_focus_exited():
	$PanelContainer/MainPanel/Outputs.hide();

func _on_InputTable_focus_entered():
	var exec = executeQuery("SELECT * FROM information_schema.tables WHERE table_schema = 'public';");
	var res = getResult(exec);
	var resPrinted = niceJson.beautify_json(to_json(res), 2).replace('"', ' ');
	$PanelContainer/MainPanel/Outputs/output.text = str(resPrinted);
	$PanelContainer/MainPanel/Outputs.show();


func _on_InputTable_focus_exited():
	$PanelContainer/MainPanel/Outputs.hide();
