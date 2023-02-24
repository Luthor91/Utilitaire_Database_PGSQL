extends Node2D

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

var tableName = '';
var nbTotalRow = 0;

var nbLimitPrintable = 100; # Nombre de ligne affichable maximale en résultat d'une requête
var nbPageQuery = 1;
var maxPage = 0;


var _user_id = OS.get_unique_id()
var _error = "";

#	var datas = executeQuery("SELECT version();");
#	print(getResult(datas));

func _init() -> void:
	_error = database.connect("connection_established", self, "_query")
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _ready():
	print("postgresql://%s:%s@%s:%d/%s" 
		% [USER, PASSWORD, HOST, PORT, DATABASE]);
	pass
 
func _physics_process(_delta: float) -> void:
	database.poll()
	
func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _query():
	var time_start = OS.get_ticks_usec();
	var nbRow = 0;
	var input = $PanelContainer/MainPanel/QueryPanel/InputQuery.text;
	var inputPrinted = input;
	if "LIMIT" in input:
		tableName = input.split("FROM")[1].split("LIMIT")[0].replace('"', "'").replace(' ', '');
		var split = input.split("LIMIT", false);
		var splitLimit = int(split[1].substr(1, split[1].length() - 2));
		if splitLimit > nbLimitPrintable:
			input = str(split[0], " LIMIT ", nbLimitPrintable, ";");
	elif "SELECT" in input and "FROM" in input:
		tableName = input.split("FROM")[1].split(" ")[1].replace('"', "'").replace(';', '').replace(' ', '');
		input = str(input.substr(0, input.length()-1), " LIMIT ", nbLimitPrintable, ";");
	nbTotalRow = getMaxRowCount(tableName);
	print("input : ", input);
	var exec = executeQuery(input); #21ms
	var result = getResult(exec); # 7ms
	var resPrinted = niceJson.beautify_json(to_json(result), 2).replace('"', ' ');
	$PanelContainer/MainPanel/ResultPanel/ResultQuery.text = resPrinted;
	nbRow = result.size()
	if (nbRow == nbLimitPrintable) && (nbTotalRow > nbLimitPrintable):
		maxPage = ceil(nbTotalRow/nbLimitPrintable);
		if nbPageQuery == maxPage:
			$PanelContainer/MainPanel/Historic/ButtonNext.text = "Suivant";
		else:
			$PanelContainer/MainPanel/Historic/ButtonNext.text = str(nbPageQuery, "/", maxPage);
		$PanelContainer/MainPanel/Historic/ButtonNext.show();

	$PanelContainer/MainPanel/TrueResultPanel/TrueResultQuery.text = str(result);
	var time_now = OS.get_ticks_usec();
	var time_elapsed = time_now - time_start;
	$PanelContainer/MainPanel/Historic/AllQuery.text += "\t" + str(inputPrinted).replace("\n", " ") + "   t=" + str(time_elapsed/1000) + "ms\n\n";
	$PanelContainer/MainPanel/Historic/LastQuery.text = "\t" + str(input);

	
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
	
func getMaxRowCount(var table):
	var getRowCount = str("SELECT reltuples AS estimate FROM pg_class WHERE relname = ", table, ";");
	var execRowCount = executeQuery(getRowCount);
	var resRowCount = getResult(execRowCount);
	if !resRowCount.empty():
		return resRowCount[0].estimate;
	else:
		return 0;
	
func pageHandler():
	if nbPageQuery == 1:
		$PanelContainer/MainPanel/Historic/ButtonLast.hide();
	else:
		$PanelContainer/MainPanel/Historic/ButtonLast.show();
	if nbPageQuery == maxPage:
		$PanelContainer/MainPanel/Historic/ButtonNext.hide();
	else:
		$PanelContainer/MainPanel/Historic/ButtonNext.show();
	
	$PanelContainer/MainPanel/Historic/ButtonNext.text = str(nbPageQuery, "/", maxPage);
	$PanelContainer/MainPanel/Historic/ButtonLast.text = str(nbPageQuery-1, "/", maxPage);

func pageQueryHandler():
	var query = $PanelContainer/MainPanel/QueryPanel/InputQuery.text;
	var getMaxLimit;
	var getLimit;
	if "LIMIT" in query:
		var split = query.split("LIMIT", false);
		getMaxLimit = int(split[1].substr(1, split[1].length() - 2));
		if getMaxLimit > getMaxRowCount(tableName):
			getMaxLimit = getMaxRowCount(tableName);
		getLimit = ceil(getMaxLimit/maxPage);
		query = str(query.substr(0, query.length()-(9+str(getLimit).length())), ' LIMIT ', getLimit, " OFFSET ",  getLimit*nbPageQuery-getLimit,";");
		print("query : ",query);
		print("getLimit = ", getLimit, "\nnbPageQuery = ", nbPageQuery, "\ngetMaxLimit = ", getMaxLimit);
	else:
		getMaxLimit = nbTotalRow;
		getLimit = ceil(getMaxLimit/maxPage);
		query = str(query.substr(0, query.length()-2), '" LIMIT ', getLimit, " OFFSET ",  getLimit*nbPageQuery-getLimit,";");
	var exec = executeQuery(query);
	var result = getResult(exec);
	var resPrinted = niceJson.beautify_json(to_json(result), 2).replace('"', ' ');
	$PanelContainer/MainPanel/ResultPanel/ResultQuery.text = resPrinted;

func _on_ButtonExecute_pressed():
	$PanelContainer/MainPanel/Historic/ButtonNext.hide();
	$PanelContainer/MainPanel/Historic/ButtonLast.hide();
	nbPageQuery = 1;
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

func _on_ButtonTrueResult_pressed():
	var txt = $PanelContainer/MainPanel/TrueResultPanel/TrueResultQuery.text
	OS.set_clipboard(txt)


func _on_ButtonResultQuery_pressed():
	var txt = $PanelContainer/MainPanel/ResultPanel/ResultQuery.text
	OS.set_clipboard(txt)

func _on_ButtonQuery_pressed():
	var txt = $PanelContainer/MainPanel/Historic/LastQuery.text
	OS.set_clipboard(txt)

func _on_ButtonClear_pressed():
	$PanelContainer/MainPanel/Historic/AllQuery.text = '';


func _on_InputQuery_mouse_entered():
	$PanelContainer/MainPanel/QueryPanel/LabelInfo.visible = true;


func _on_InputQuery_mouse_exited():
	$PanelContainer/MainPanel/QueryPanel/LabelInfo.visible = false;


func _on_ButtonNext_pressed():
	if nbPageQuery < maxPage:
		nbPageQuery += 1;
	pageHandler();
	pageQueryHandler();

func _on_ButtonLast_pressed():
	if nbPageQuery > 1:
		nbPageQuery -= 1;
	pageHandler();
	pageQueryHandler();

func _on_ButtonGoTo_pressed():
	var page = int($PanelContainer/MainPanel/Historic/goTo.text);
	if page > maxPage:
		nbPageQuery = maxPage;
		$PanelContainer/MainPanel/Historic/goTo.text = str(maxPage);
	else:
		nbPageQuery = page;
	pageHandler();
	pageQueryHandler();
