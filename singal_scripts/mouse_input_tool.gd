class_name MouseInputTool
extends RefCounted

## 鼠标输入的辅助类
##
## [MouseInputTool] 提供若干事件相应的信号，必须在构建时提供 input_signal 或手动调用 [method input] 才会正常工作 [br]
## [br]
## [b]Warning[/b]: 暂时对 [Control] 的支持不好

## 触发双击的阈值，单位为秒
var double_click_threshold: float = 0.2

## 只有两次点击的距离小于该值才会发出 [signal double_click] 信号
var double_click_range: float = 10.0

## 触发长点击的阈值，单位为秒
var long_click_threshold: float = 1.0

## 只有两次点击的距离小于该值才会发出 [signal long_click] 信号
var long_click_range: float = 10.0

## 触发长按的阈值，单位为秒
var long_press_threshold: float = 0.5


## 当 event 来自 [Control]，mouse_pos 使用 [Control] 的本地坐标系 [br]
## 否则使用该节点坐在的 [Viewport] 的坐标系
signal clicked(mouse_pos: Vector2)

## 当 event 来自 [Control]，mouse_pos 使用 [Control] 的本地坐标系 [br]
## 否则使用该节点坐在的 [Viewport] 的坐标系
signal double_clicked(mouse_pos: Vector2)

## 当 event 来自 [Control]，mouse_pos 使用 [Control] 的本地坐标系 [br]
## 否则使用该节点坐在的 [Viewport] 的坐标系
signal long_clicked(start_mouse_pos: Vector2, last_mouse_pos: Vector2)

## 长时间按下时触发
signal long_pressed

## 相对上一帧鼠标所在位置的插值
signal drag(velocity: Vector2)

var _is_pressing: bool = false

var _last_pressed_time: int = -1
var _last_released_time: int = -1

var _last_pressed_pos: Vector2 = Vector2.INF
var _last_released_pos: Vector2 = Vector2.INF

var _last_mouse_pos: Vector2 = Vector2.INF

var _timer: float = 0.0

var _current_click_action_was_emit_long_pressed_signal: bool = false

var _has_delta_time_node: Node

func _setup_press_state(event: InputEventMouse) -> void:
	_last_pressed_time = Time.get_ticks_msec()
	_last_pressed_pos = event.position
	_is_pressing = true

func _setup_release_state(event: InputEventMouse) -> void:
	_last_released_time = Time.get_ticks_msec()
	_last_released_pos = event.position
	reset()

## 重置状态，可在必要时手动调用
func reset() -> void:
	_is_pressing = false
	_timer = 0.0
	_current_click_action_was_emit_long_pressed_signal = false

## 处理逻辑的主要函数 [br]
## 可以在通过在构造函数中传入input函数来链接，也可以手动在需要的位置调用此函数
func input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				
				if (Time.get_ticks_msec() - _last_pressed_time) / 1000.0 < double_click_threshold and event.position.distance_to(_last_pressed_pos) < double_click_range:
					double_clicked.emit(event.position)
				else:
					clicked.emit(event.position)
				
				_setup_press_state(event)
			else:
				
				if (Time.get_ticks_msec() - _last_pressed_time) / 1000.0 > long_click_threshold and event.position.distance_to(_last_pressed_pos) < double_click_range:
					long_clicked.emit(_last_mouse_pos, event.position)
				
				_setup_release_state(event)
	elif event is InputEventMouseMotion:
		if _is_pressing:
			if _last_mouse_pos != event.position:
				drag.emit(event.position - _last_mouse_pos)
	
	_last_mouse_pos = event.position


func _process_1() -> void:
	_process(_has_delta_time_node.get_process_delta_time())
	pass

func _process(delta: float = -1) -> void:
	
	if _is_pressing:
		_timer += delta
		
		if not _current_click_action_was_emit_long_pressed_signal and _timer >= long_press_threshold:
			long_pressed.emit()
			_current_click_action_was_emit_long_pressed_signal = true
	
	pass

## 两个参数都可为空，input_signal为空时请手动调用input函数, prcess_signal 为空时根据 [SceneTree] 更新，若传入则应自带 delta 参数
func _init(input_signal: Signal = Signal(), process_signal: Signal = Signal()) -> void:
	if input_signal != Signal():
		input_signal.connect(input)
	
	if process_signal != Signal():
		process_signal.connect(_process)
	elif Engine.get_main_loop() is SceneTree:
		(Engine.get_main_loop() as SceneTree).process_frame.connect(_process_1)
		_has_delta_time_node = (Engine.get_main_loop() as SceneTree).root
	

