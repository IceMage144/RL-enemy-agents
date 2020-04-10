extends Node

func get_action(features, legal_actions):
	$BehaviorBlackboard.set("features", features)
	$BehaviorBlackboard.set("legal_actions", legal_actions)
	$BehaviorBlackboard.set("result", {})
	$BehaviorTree.tick(self, $BehaviorBlackboard)
	var result = $BehaviorBlackboard.get("result")
	return result["action"]