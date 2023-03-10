extends Node2D

func _ready():
	pass # Replace with function body.

func _on_ButtonKeyWordSQL_pressed():
	var keyWord = $PanelContainer/MainPanel/Buttons/KeyWord/Search.text.to_lower();
	var url = '';
#	 OS.shell_open("mailto:example@example.com")
	if keyWord.empty():
		url = "https://www.postgresql.org/docs/current/";
	else:
		url = str("https://www.postgresql.org/docs/current/sql-", keyWord, ".html");
	var _err = OS.shell_open(url);

func _on_ButtonPGSQL_Version_pressed():
	var _err = OS.shell_open("https://www.enterprisedb.com/downloads/postgres-postgresql-downloads");
