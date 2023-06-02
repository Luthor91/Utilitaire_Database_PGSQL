extends Node2D

#	Revoir fonction reload 

var database := PostgreSQLClient.new();
var niceJson = JSONBeautifier.new();

enum PopupCondition {
	SUPERIEUR
	INFERIEUR
	EGAL
	NON_EGAL
	SUPERIEUR_EGAL
	INFERIEUR_EGAL
	LIKE
}

enum PopupJointure {
	LEFT_JOIN
	RIGHT_JOIN
	INNER_JOIN
	FULL_JOIN
	CROSS_JOIN
	SELF_JOIN
	NATURAL_JOIN
	UNION_JOIN
}

enum PopupOrdre {
	ASC
	DESC
}

onready var USER = Globals.USER;
onready var PASSWORD = Globals.PASSWORD;
onready var HOST = Globals.HOST;
onready var DATABASE = Globals.DATABASE;
onready var PORT = Globals.PORT;

############################################
#	Gestion des requêtes
#

var tableName = '';			#Nom de la table sélectionné
var allColumnsOfTable = {};	#Toutes les colonnes d'une table
var allTables = [];			#Toutes les tables de la base de données
var arrTablesColumns = [];	#Contient toutes les tables et leurs colonnes
var argsQuery = [];			#Arguments de la requête en cours
var strQuery = '';			#Requête en cours

# Gestion des pages
var nbTotalRow = 0;
var nbLimitPrintable = 100; # Nombre de ligne affichable maximale en résultat d'une requête
var nbPageQuery = 1;
var maxPage = 0;

var _error = "";

############################################
#	Méthodes d'initialisation de données
#

func _init() -> void:
	_error = database.connect("connection_established", self, "_query")
	_error = database.connect("authentication_error", self, "_authentication_error")
	_error = database.connect("connection_closed", self, "_close")

func _ready():
	argsQuery.resize(20);
	var mb = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/ConditionSelect;
	var popup = mb.get_popup();
	popup.add_item("Supérieur", PopupCondition.SUPERIEUR);
	popup.add_item("Inférieur", PopupCondition.INFERIEUR);
	popup.add_item("Egal", PopupCondition.EGAL);
	popup.add_item("Non égal", PopupCondition.NON_EGAL);
	popup.add_item("Supérieur et égal", PopupCondition.SUPERIEUR_EGAL);
	popup.add_item("Inférieur et égal", PopupCondition.INFERIEUR_EGAL);
	popup.add_item("Like", PopupCondition.LIKE);
	
	mb = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/JointureSelect;
	popup = mb.get_popup();
	popup.add_item("LEFT JOIN", PopupJointure.LEFT_JOIN);
	popup.add_item("RIGHT JOIN", PopupJointure.RIGHT_JOIN);
	popup.add_item("INNER JOIN", PopupJointure.INNER_JOIN);
	popup.add_item("FULL JOIN", PopupJointure.FULL_JOIN);
	popup.add_item("CROSS JOIN", PopupJointure.CROSS_JOIN);
	popup.add_item("SELF JOIN", PopupJointure.SELF_JOIN);
	popup.add_item("NATURAL JOIN", PopupJointure.NATURAL_JOIN);
	popup.add_item("UNION JOIN", PopupJointure.UNION_JOIN);

	mb = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/OrdreSelect;
	popup = mb.get_popup();
	popup.add_item("ASCENDANT", PopupOrdre.ASC);
	popup.add_item("DESCENDANT", PopupOrdre.DESC);
	
	var buttonsQuery = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.get_children();
	for btn in buttonsQuery:
		_error = btn.connect("pressed", self, "_on_ButtonMainTypeQuery_pressed", [btn]);
	_error = database.connect_to_host("postgresql://%s:%s@%s:%d/%s" % [USER, PASSWORD, HOST, PORT, DATABASE])

############################################
#	Boucle infini
#

func _physics_process(_delta: float) -> void:
	var buttonsCondition = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition;
	var buttonsJointure = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure;
	var buttonsLimites = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites;
	var buttonsOrdre = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre;
	var _output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	var input1 = '';
	var input2 = '';
	for btn in buttonsJointure.get_children():
		if btn.get_class() == "LineEdit":
			if btn.text == '"TableName"."Column"':
				continue;
			input1 = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/firstKey.text;
			input2 = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/secondKey.text;
			var regex1 = RegEx.new()
			var regex2 = RegEx.new()
			regex1.compile('(\\w+\\.\\w+)');
			regex2.compile('("\\w+"\\."\\w+")');
			if regex1.search(input1) \
				&& !'"' in input1 \
				&& "." in input1 \
				&& input1 != argsQuery[7]:
				input1 = str('"', input1.split('.')[0], '"."', input1.split('.')[1], '"');
				if '_' in input1:
					input2 = str('"', input1.split('.')[1].split('_')[2], '."id"');
					getDictColumnsOf(input1.split('.')[1].split('_')[2]);
				elif 'id' in input1:
					input2 = str(''); 
				else:
					input2 = str('');
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/firstKey.text = input1;
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/secondKey.text = input2;
			elif regex2.search(input1) \
				&& "." in input1 \
				&& input2 != argsQuery[8]:
				if '_' in input2:
					input2 = str(input1.split('.')[1].split('_')[2], '.id');
					getDictColumnsOf(input1.split('.')[1].split('_')[2]);
				elif 'id' in input1:
					input2 = str(''); 
				else:
					input2 = str('');
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/firstKey.text = input1;
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/secondKey.text = input2;
			argsQuery[7] = input1;
			argsQuery[8] = input2;
	for btn in buttonsCondition.get_children():
		if btn.get_class() == "LineEdit":
			input1 = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/firstColumn.text;
			input2 = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/secondColumn.text;
			var regex = RegEx.new()
			regex.compile('(\\w+\\.\\w+)');
			if regex.search(input1) \
				&& !'"' in input1 \
				&& "." in input1 \
				&& input1 != argsQuery[7]:
				input1 = str('"', input1.split('.')[0], '"."', input1.split('.')[1], '"');
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/firstColumn.text = input1;
			argsQuery[3] = input1;
			argsQuery[5] = input2;
	for btn in buttonsLimites.get_children():
		if btn.get_class() == "LineEdit":
			argsQuery[9] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites/inputLimit.text;
			argsQuery[10] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites/inputOffset.text;
	for btn in buttonsOrdre.get_children():
		if btn.get_class() == "LineEdit":
			input1 = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/orderColumn.text;
			var regex = RegEx.new()
			regex.compile('(\\w+\\.\\w+)');
			if regex.search(input1) \
				&& !'"' in input1 \
				&& "." in input1 \
				&& input1 != argsQuery[7]:
				input1 = str('"', input1.split('.')[0], '"."', input1.split('.')[1], '"');
				$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/orderColumn.text = input1;
			argsQuery[11] = input1;
	reloadTableColumn();
	database.poll();

############################################
#	Méthodes des signaux de la database 
#

func _authentication_error(error_object: Dictionary) -> void:
	prints("Error connection to database:", error_object["message"])

func _query():
	printButtonsTable();

func _close(clean_closure := true) -> void:
	prints("DB CLOSE,", "Clean closure:", clean_closure)

func _exit_tree() -> void:
	database.close()

############################################
#	Méthodes de gestion des requêtes
#

func executeQuery(var _query):
	if not database.error_object.empty():
		prints("Error:", database.error_object)
	return database.execute(_query);

func queryHandler(var input):
	var time_start = OS.get_ticks_usec();
	var nbRow = 0;
	var inputPrinted = input;
	if "LIMIT" in input:
		tableName = input.split("FROM")[1].split("LIMIT")[0].replace('"', "'").replace(' ', '');
		var split = input.split("LIMIT", false);
		var splitLimit = int(split[1].substr(1, split[1].length() - 2));
		nbTotalRow = splitLimit;
		if splitLimit > nbLimitPrintable:
			input = str(split[0], " LIMIT ", nbLimitPrintable, ";");
	elif "SELECT" in input and "FROM" in input:
		tableName = input.split("FROM")[1].split(" ")[1].replace('"', "'").replace(';', '').replace(' ', '');
		input = str(input.substr(0, input.length()-1), " LIMIT ", nbLimitPrintable, ";");
		nbTotalRow = getMaxRowCount(tableName);
	var exec = executeQuery(input); #21ms
	var result = getResult(exec); # 7ms
	var resPrinted = niceJson.beautify_json(to_json(result), 2);
	$PanelContainer/MainPanel/ResultPanel/ResultQuery.text = resPrinted.replace('"', '').replace('\\', '');
	nbRow = result.size()
	if (nbRow == nbLimitPrintable) && (nbTotalRow > nbLimitPrintable):
		maxPage = ceil(nbTotalRow/nbLimitPrintable);
		$PanelContainer/MainPanel/Historic/ButtonNext.show();
		$PanelContainer/MainPanel/Historic/ButtonNext.text = str(nbPageQuery, "/", maxPage);
		if nbPageQuery == maxPage:
			$PanelContainer/MainPanel/Historic/ButtonNext.text = "Suivant";
	$PanelContainer/MainPanel/TrueResultPanel/TrueResultQuery.text = str(result);
	var time_now = OS.get_ticks_usec();
	var time_elapsed = time_now - time_start;
	if resPrinted == '{}':
		$PanelContainer/MainPanel/ResultPanel/ResultQuery.text = niceJson.beautify_json(to_json(database.error_object), 2).replace('"', ' ');
		$PanelContainer/MainPanel/TrueResultPanel/TrueResultQuery.text = to_json(database.error_object);
	else:
		$PanelContainer/MainPanel/Historic/AllQuery.text += "\t" + str(inputPrinted).replace("\n", " ") + "   t=" + str(time_elapsed/1000) + "ms\n\n";
		$PanelContainer/MainPanel/Historic/LastQuery.text = "\t" + str(input);

############################################
#	Affichage de données ou boutons de tables / colonnes
#

func showTables():
	var nameTable = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name;");
	var res = getResult(nameTable);
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	for table in res:
		$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res[table]['table_name'], "\n");

func showColumns():
	var nameTable = $PanelContainer/MainPanel/QueryPanel/PanelColumn/InputColonne.text;
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", nameTable, "' ORDER BY ordinal_position;");
	var execColumn = executeQuery(query);
	var res = getResult(execColumn);
	$PanelContainer/MainPanel/QueryResult/ResultQuery.text = '';
	for column in res:
		$PanelContainer/MainPanel/QueryResult/ResultQuery.text += str(res[column]['column_name'], "\n");

func printButtonsColumn():
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns/ScrollContainer/ControlColumn;
	var temps_arrColumns = [];
	var sizeX = 256;
	var sizeY = 20;
	var incrSizeY = 0;
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", tableName, "' ORDER BY column_name DESC;");
	var nameColumns = executeQuery(query);
	var res = getResult(nameColumns);
	var btnEventAlreadyDefined = false;
	for btn in node.get_children():
		if btn.text == '*':
			btnEventAlreadyDefined = true;
	if btnEventAlreadyDefined == false:
		var btn = Button.new();
		btn.set_position(
			Vector2(0, 
			sizeY*incrSizeY));
		btn.rect_min_size = Vector2(sizeX,sizeY);
		btn.text = '*';
		btn.connect("pressed", self, "_on_ButtonMainColumn_pressed", [btn]);
		node.add_child(btn);
		btn.show();
		incrSizeY += 1;
	for id in res:
		if arrTablesColumns.find(res[id]['column_name']) == -1:
			arrTablesColumns.append(res[id]['column_name']);
		else:
			continue;
		var btn = Button.new();
		btn.set_position(
			Vector2(0, 
			sizeY*incrSizeY));
		btn.rect_min_size = Vector2(sizeX,sizeY);
		btn.text = res[id]['column_name'];
		temps_arrColumns.append(res[id]['column_name']);
		btn.connect("pressed", self, "_on_ButtonMainColumn_pressed", [btn]);
		node.add_child(btn);
		btn.show();
		incrSizeY += 1;
	allColumnsOfTable.merge({tableName:temps_arrColumns}, true);
	allColumnsOfTable['length'] = allColumnsOfTable[tableName].size();
	node.rect_min_size = Vector2(264,sizeY*node.get_child_count());
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns/ScrollContainer.get_h_scrollbar().rect_scale.x = 0;

func printButtonsTable():
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables/ScrollContainer/ControlTable;
	var sizeX = 256;
	var sizeY = 20;
	var incrSizeY = 0;
	var nameTables = executeQuery("SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY table_name ASC;");
	var res = getResult(nameTables);
	for id in res:
		if arrTablesColumns.find(res[id]['table_name']) == -1:
			arrTablesColumns.append(res[id]['table_name']);
		var btn = Button.new();
		btn.set_position(
			Vector2(0, 
			sizeY*incrSizeY));
		btn.rect_min_size = Vector2(sizeX,sizeY);
		btn.text = res[id]['table_name'];
		btn.connect("pressed", self, "_on_ButtonMainTable_pressed", [btn]);
		node.add_child(btn);
		btn.show();
		incrSizeY += 1;
		node.rect_min_size = Vector2(264,sizeY*node.get_child_count());
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables/ScrollContainer.get_h_scrollbar().rect_scale.x = 0;

############################################
#	Méthodes permettant d'avoir des données
#

func getDictColumnsOf(var local_tableName, var arrOutput = {}):
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", local_tableName, "' ORDER BY ordinal_position;");
	var execColumn = executeQuery(query);
	var res = getResult(execColumn);
	var tempArray = [];
	for column in res:
		if !arrOutput.has(res[column]['column_name']):
			tempArray.append(res[column]['column_name']);
	arrOutput.merge({local_tableName:tempArray}, true);
	return arrOutput;

func getArrColumnsOf(var tablename, var arrOutput = []):
	var query = str("SELECT column_name FROM information_schema.columns WHERE table_name = '", tablename, "' ORDER BY ordinal_position;");
	var execColumn = executeQuery(query);
	var res = getResult(execColumn);
	arrOutput[tablename] = [];
	arrOutput[tablename].resize(100);
	for column in res:
		if arrOutput[tablename].find(res[column]['column_name']) == -1:
			arrOutput[tablename].append(res[column]['column_name'])
	return arrOutput[tablename];

func getAllColumnsFromTablesAndPrint(var controlNode):
	var label = '';
	if controlNode == 'Columns':
		$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/ScrollColumns.show();
		label = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/ScrollColumns/VBoxContainer/Columns;
	elif controlNode == 'Ordre':
		$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/ScrollColumns.show();
		label = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/ScrollColumns/VBoxContainer/Columns;
	var tempDict = allColumnsOfTable.duplicate(true);
	if tempDict.has('length'):
		tempDict.erase('length');
	label.rect_min_size = Vector2(248,184);
	label.text = niceJson.beautify_json(to_json(tempDict),2).replace('"', ' ');
	tempDict = {};

func getOnlyKeysFromTablesAndPrint():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/ScrollColumns.show();
	var label = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/ScrollColumns/VBoxContainer/ColumnKey;
	var local_allTables = allTables.duplicate(true);
	var dict = {};
	for table in local_allTables:
		dict.merge(getDictColumnsOf(table), true);
	for table in dict:
		if typeof(dict[table]) != TYPE_ARRAY :
			continue;
		var index = -1;
		for column in table:
			var nbValSkipped = 0;
			while nbValSkipped < dict[table].size()-1:
				index += 1;
				if index >= dict[table].size():
					index = 0;
				if 'id' in dict[table][index].to_lower() or 'fk' in dict[table][index].to_lower():
					nbValSkipped += 1;
					continue;
				dict[table].remove(index);
	label.rect_min_size = Vector2(248,184);
	label.text = niceJson.beautify_json(to_json(dict),2).replace('"', ' ');

func getColumnTypeAndPrint(var local_tableName):
	tableName = tableName.replace('"', "");
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input/ScrollColumns.show();
	var label: Node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input/ScrollColumns/VBoxContainer/ColumnType;
	var query: String = str("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '", local_tableName, "';");
	var exec = executeQuery(query);
	var res = getResult(exec);
	var output: String = '';
	for index in res:
		output += str(res[index]['column_name'], ' : ',  res[index]['data_type'], '\n\n');
	label.rect_min_size = Vector2(248,184);
	label.text = output;

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
				var columnName = str(data.row_description[numberOfColumn]["field_name"]);
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

############################################
#	Méthodes permettant de gérer les pages
#

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
	var query = strQuery;
	var getMaxLimit;
	var getLimit;
	if "LIMIT" in query:
		var split = query.split("LIMIT", false);
		getMaxLimit = int(split[1].substr(1, split[1].length() - 2));
		if getMaxLimit > getMaxRowCount(tableName):
			getMaxLimit = getMaxRowCount(tableName);
		getLimit = ceil(getMaxLimit/maxPage);
		query = str(query.substr(0, query.length()-(9+str(getLimit).length())), '" LIMIT ', getLimit, " OFFSET ",  getLimit*nbPageQuery-getLimit,";");
	else:
		getMaxLimit = nbTotalRow;
		getLimit = ceil(getMaxLimit/maxPage);
		query = str(query.substr(0, query.length()-2), ' LIMIT ', getLimit, " OFFSET ",  getLimit*nbPageQuery-getLimit,";");
	var exec = executeQuery(query);
	var result = getResult(exec);
	var resPrinted = niceJson.beautify_json(to_json(result), 2).replace('"', '');
	$PanelContainer/MainPanel/ResultPanel/ResultQuery.text = resPrinted;

############################################
#	Méthodes permettant de gérer les potentielles erreurs d'une série ou d'une donnée(s)
#

func isNullInArray(var arr):
	var id = 0;
	for val in arr:
		if val == null:
			val = '';
		arr[id] = val;
		id += 1;
	return arr;

func reloadTableColumn():
	var inputTables = [];
	inputTables.resize(5);
	inputTables[0] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/firstKey.text;
	inputTables[1] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/secondKey.text;
	inputTables[2] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/firstColumn.text;
	inputTables[3] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/secondColumn.text;
	inputTables[4] = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/orderColumn.text;
	for table in inputTables:
		if '.' in table:
			var table1 = table.split('.')[0].replace('"', '');
			var dictTemp = getDictColumnsOf(table1);
			if !allColumnsOfTable.has(table1):
				allColumnsOfTable.merge(dictTemp, true);
#				allColumnsOfTable[table1] = { allColumnsOfTable[table1].size() : dictTemp };


############################################
#	Copier le résultat de la requête
#

func _on_ButtonTrueResult_pressed():
	var txt = $PanelContainer/MainPanel/TrueResultPanel/TrueResultQuery.text
	OS.set_clipboard(txt)

func _on_ButtonResultQuery_pressed():
	var txt = $PanelContainer/MainPanel/ResultPanel/ResultQuery.text
	OS.set_clipboard(txt)

func _on_ButtonQuery_pressed():
	var txt = $PanelContainer/MainPanel/Historic/LastQuery.text
	OS.set_clipboard(txt)

############################################
#	Vider les champs textes
#

func _on_ButtonClear_pressed():
	$PanelContainer/MainPanel/Historic/AllQuery.text = '';

func _on_ButtonClearUsedQuery_pressed():
	allColumnsOfTable = {};
	$PanelContainer/MainPanel/QueryPanel/UsedQuery.text = '';

############################################
#	Gestion des pages
#

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
	if maxPage == 0:
		return;
	var page = int($PanelContainer/MainPanel/Historic/goTo.text);
	if page > maxPage:
		nbPageQuery = maxPage;
		$PanelContainer/MainPanel/Historic/goTo.text = str(maxPage);
	else:
		nbPageQuery = page;
	pageHandler();
	pageQueryHandler();

############################################
#	Gestion des boutons pour fabriquer la requête
#

func _on_ButtonQueryType_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonTable_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonColumn_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns;
	printButtonsColumn();
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonCondition_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonJointure_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonLimites_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

func _on_ButtonOrder_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();

############################################
#	Gestion des menus de sélection desconditions, jointure et ordres
#

func _on_ConditionSelect_item_selected(index):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	if output.text.empty():
		output.text = str('Condition : ', PopupCondition.keys()[index], '\n');
	elif output.text.find('Condition : ') == -1:
		output.text += str('Condition : ', PopupCondition.keys()[index], '\n');
	match index:
		PopupCondition.SUPERIEUR:
			argsQuery[4] = '>';
		PopupCondition.INFERIEUR:
			argsQuery[4] = '<';
		PopupCondition.EGAL:
			argsQuery[4] = '=';
		PopupCondition.NON_EGAL:
			argsQuery[4] = '!=';
		PopupCondition.SUPERIEUR_EGAL:
			argsQuery[4] = '>=';
		PopupCondition.INFERIEUR_EGAL:
			argsQuery[4] = '<=';
		PopupCondition.LIKE:
			argsQuery[4] = 'LIKE';

func _on_JointureSelect_item_selected(index):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	if output.text.empty():
		output.text = str('Jointure : ', PopupJointure.keys()[index], '\n');
	elif output.text.find('Jointure : ') == -1:
		output.text += str('Jointure : ', PopupJointure.keys()[index], '\n');
	match index:
		PopupJointure.LEFT_JOIN:
			argsQuery[6] = 'LEFT JOIN';
		PopupJointure.RIGHT_JOIN:
			argsQuery[6] = 'RIGHT JOIN';
		PopupJointure.INNER_JOIN:
			argsQuery[6] = 'INNER JOIN';
		PopupJointure.FULL_JOIN:
			argsQuery[6] = 'FULL JOIN';
		PopupJointure.CROSS_JOIN:
			argsQuery[6] = 'CROSS JOIN';
		PopupJointure.SELF_JOIN:
			argsQuery[6] = 'SELF JOIN';
		PopupJointure.NATURAL_JOIN:
			argsQuery[6] = 'NATURAL JOIN';
		PopupJointure.UNION_JOIN:
			argsQuery[6] = 'UNION JOIN';

func _on_OrdreSelect_item_selected(index):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	if output.text.empty():
		output.text = str('Ordre : ', PopupOrdre.keys()[index], '\n');
	elif output.text.find('Ordre : ') == -1:
		output.text += str('Ordre : ', PopupOrdre.keys()[index], '\n');
	match index:
		PopupOrdre.ASC:
			argsQuery[12] = 'ASC';
		PopupOrdre.DESC:
			argsQuery[12] = 'DESC';

############################################
#	Calcul et exécution de la requête
#

func _on_ButtonCalcQuery_pressed():
	if !range(argsQuery.size()).has(0):
		return;
	argsQuery = isNullInArray(argsQuery);
	var strCond: String = '';
	var strJoin: String = '';
	var strLimits: String = '';
	var strOrder: String = '';
	var strPrinted: String = '';
	var verbose = argsQuery[-1];
	var typeQuery = argsQuery[0];
	var mainTable = argsQuery[1];
	var mainColumn = argsQuery[2];
	var firstCond = argsQuery[3];
	var cond = argsQuery[4];
	var secondCond = argsQuery[5];
	var join = argsQuery[6];
	var firstKey = argsQuery[7];
	var secondKey = argsQuery[8];
	var limit = argsQuery[9];
	var offset = argsQuery[10];
	var order = argsQuery[11];
#	var values = argsQuery[12];
	var values = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input/InputValue.text;
	match(typeQuery.to_upper()):
		'SELECT':
			if !verbose.empty():
				strPrinted += str(verbose, '\n');
			strPrinted += str(typeQuery, ' \n', mainTable , '.');
			if mainColumn == '"*"':
				mainColumn = str(mainColumn).replace('"', '');
			strPrinted += str(mainColumn, '\nFROM \n', mainTable);
			if cond.to_upper() == 'LIKE':
				secondCond = str("'", secondCond, "'");
			if !join.empty():
				strJoin = str(join, ' ', secondKey.split('.')[0],' ON ', firstKey, ' = ', secondKey);
				strPrinted += str('\n', join, ' ', secondKey.split('.')[0],' ON\n', firstKey, ' = ', secondKey);
			if !firstCond.empty() and !cond.empty() and !secondCond.empty():
				strCond = str('WHERE ', firstCond, ' ', cond, ' ', secondCond);
				strPrinted += str('\n');
			strPrinted += str(strCond);
			if !offset.empty():
				strLimits += str('OFFSET ', offset);
				strPrinted += str('\nOFFSET ');
			strPrinted += str(offset);
			if !limit.empty():
				strLimits += str(' LIMIT ', limit);
				strPrinted += str('\nLIMIT ');
			strPrinted += str(limit);
			if !order.empty():
				strOrder += str('ORDER BY ', order);
				strPrinted += str('\nORDER BY ');
			strPrinted += str(order);
			strQuery = str(verbose, typeQuery, ' ', mainTable , '.', mainColumn, 
				' FROM ', mainTable , ' ', strJoin, ' ', strCond, ' ', strOrder, ' ', strLimits, ';');
		'INSERT':
			var vals: Array = values.split(',', true);
			mainColumn = str(mainColumn).replace('"', '');
			var strVal: String = '';
			for val in vals:
				if typeof(val) == TYPE_STRING:
					strVal += str("('", val, "'),");
				else:
					strVal += str("(", val, "),");
			strVal.erase(strVal.length()-1, 1);
			strPrinted = str(typeQuery, ' INTO ', mainTable, '\n (', mainColumn, ')\nVALUES\n', strVal, ';');
			strQuery = str(typeQuery, ' INTO ', mainTable , '(', mainColumn, ') VALUES', strVal, ';');
		'UPDATE':
			mainColumn = str(mainColumn).replace('"', '');
			if typeof(values) == TYPE_STRING:
				values = str("'", values, "'");
			else:
				values = str(values);
			if !firstCond.empty() and !cond.empty() and !secondCond.empty():
				strCond = str('WHERE ', firstCond, ' ', cond, ' ', secondCond);
			strPrinted = str(typeQuery, ' ', mainTable, '\n SET ', mainColumn, '=\n', values, '\n', strCond, ';');
			strQuery = str(typeQuery, ' ', mainTable, ' SET ', mainColumn, '=', values, ' ', strCond, ';');
		'DELETE':
			mainColumn = str(mainColumn).replace('"', '');
			if !firstCond.empty() and !cond.empty() and !secondCond.empty():
				strCond = str('WHERE ', firstCond, ' ', cond, ' ', secondCond);
			strPrinted = str(typeQuery, ' FROM ', mainTable, '\n', strCond, ';');
			strQuery = str(typeQuery, ' FROM ', mainTable, ' ', strCond, ';');
		'TRUNCATE':
			strPrinted = str(typeQuery, ' TABLE \n', mainTable,';');
			strQuery = str(typeQuery, ' TABLE ', mainTable, ';');
		'_':
			return;
	$PanelContainer/MainPanel/QueryPanel/UsedQuery.text = strPrinted;

func _on_ButtonExecuteQuery_pressed():
	queryHandler(strQuery);

############################################
#	Affichage de données lors du focus des entrées texte lors de la sélection de la requête
#

func _on_firstKey_focus_entered():
	getOnlyKeysFromTablesAndPrint();

func _on_secondKey_focus_entered():
	getOnlyKeysFromTablesAndPrint();

func _on_firstColumn_focus_entered():
	getAllColumnsFromTablesAndPrint('Columns');

func _on_secondColumn_focus_entered():
	getAllColumnsFromTablesAndPrint('Columns');

func _on_orderColumn_focus_entered():
	getAllColumnsFromTablesAndPrint('Ordre');
	
func _on_InputValue_focus_entered():
	getColumnTypeAndPrint(argsQuery[1]);

func _on_ColumnKey_focus_exited():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure/ScrollColumns.hide();

func _on_Columns_focus_exited():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/ScrollColumns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/ScrollColumns.hide();


func _on_ButtonInput_pressed():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Tables.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Columns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/QueryType.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Jointure.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Limites.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre.hide();
	var node = $PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input;
	node.rect_position = Vector2.ZERO;
	if node.visible == false:
		node.show();
	else:
		node.hide();


func _on_ColumnType_focus_exited():
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Condition/ScrollColumns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Ordre/ScrollColumns.hide();
	$PanelContainer/MainPanel/ScrollContainer/PanelBtn/Input/ScrollColumns.hide();


func _on_ButtonVerbose_toggled(button_pressed):
	if button_pressed:
		argsQuery[-1] = "EXPLAIN ANALYZE ";
	else:
		argsQuery[-1] = '';

func _on_ButtonMainTypeQuery_pressed(btn: Button):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	argsQuery[0] = btn.text;
	if output.text.empty():
		output.text = str('Main type : ', btn.text, '\n');
	elif output.text.find(btn.text) == -1:
		if output.text.find('Main type : ') != -1:
			output.text += str('Type : ', btn.text, '\n');
		else:
			output.text += str('Main type : ', btn.text, '\n');

func _on_ButtonMainColumn_pressed(btn: Button):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	argsQuery[2] = str('"', btn.text, '"');
	if output.text.empty():
		output.text = str('Main column : ', btn.text, '\n');
	elif output.text.find(btn.text) == -1:
		if output.text.find('Main column : ') != -1:
			output.text += str('Column : ', btn.text, '\n');
		else:
			output.text += str('Main column : ', btn.text, '\n');
	
func _on_ButtonMainTable_pressed(btn: Button):
	var output = $PanelContainer/MainPanel/QueryPanel/UsedQuery;
	if output.text.ends_with(';'):
		output.text = '';
	argsQuery[1] = str('"', btn.text, '"');
	if output.text.empty():
		output.text = str('Main table : ', btn.text, '\n');
		allTables.append(btn.text);
	elif output.text.find(btn.text) == -1:
		if output.text.find('Main table : ') != -1:
			output.text += str('Table : ', btn.text, '\n');
			allTables.append(btn.text);
		else:
			output.text += str('Main table : ', btn.text, '\n');
			allTables.append(btn.text);
	tableName = btn.text;

