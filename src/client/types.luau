--!strict
export type Character = {
	is_dead: boolean,
	
	model: Model,
	humanoid: Humanoid?,
	
	cframes: {CFrame},
	last_cframes: {CFrame},
	
	kinematics: { [string]: CharacterKinematic },

	left_foot: Attachment?,
	right_foot: Attachment?,
	waist_motor: Motor6D?,
	
	connections: { RBXScriptConnection }
}

export type CharacterKinematic = {
	control: IKControl,
	control_target: Attachment?,
	control_target_identity: CFrame?
}

return 0