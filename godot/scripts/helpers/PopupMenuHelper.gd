extends RefCounted
class_name PopupMenuHelper

## Reabertura de popup após upgrade: a condição é a mesma em todos os menus.

static func can_reopen(keep_open: bool, selected_index: int, count: int, choosing_upgrade: bool, game_over: bool) -> bool:
	if not keep_open:
		return false
	if selected_index < 0 or selected_index >= count:
		return false
	if choosing_upgrade or game_over:
		return false
	return true
