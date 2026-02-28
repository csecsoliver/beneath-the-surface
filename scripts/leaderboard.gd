extends Node

const SERVER_URL := "https://save.temp.olio.ovh"
const LEADERBOARD_URL := "https://save.temp.olio.ovh/leaderboard"
const SECRET := "underwater_"

var _is_web_build: bool = OS.has_feature("web")

## Submit score silently (fire and forget, no waiting, no UI)
func submit_score(name: String, time: float) -> void:
	var score_data := {
		"name": name,
		"time": time,
		"date": Time.get_datetime_string_from_system()
	}
	var json_str := JSON.stringify(score_data)
	var obscured := _obscure(json_str)

	var body := JSON.new().stringify({"data": obscured})

	var http := HTTPRequest.new()
	add_child(http)

	if _is_web_build:
		http.timeout = 10.0

	http.request_completed.connect(_cleanup_http.bind(http), CONNECT_ONE_SHOT)

	var headers := [
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Requested-With: XMLHttpRequest"
	]

	http.request(SERVER_URL + "/submit", headers, HTTPClient.METHOD_POST, body)

## Open the leaderboard in the user's browser
func open_leaderboard() -> void:
	if _is_web_build:
		JavaScriptBridge.eval("window.open('%s', '_blank')" % LEADERBOARD_URL)
	else:
		OS.shell_open(LEADERBOARD_URL)

func _obscure(data: String) -> String:
	var combined := SECRET + data
	var bytes := combined.to_utf8_buffer()
	return Marshalls.raw_to_base64(bytes)

func _cleanup_http(http: HTTPRequest, _result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	http.queue_free()
