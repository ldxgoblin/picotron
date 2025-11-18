--[[pod_format="raw",created="2025-07-14 23:40:00",modified="2025-07-15 05:13:42",revision=68]]
local script = {
	["intro"] = {
		{text="choices with seeking"},
		"query"
	},
	
	["query"] = {
		{
			text="pick one of these choices ok",
			choices = {
				{text="choice 1 (correct)", 		result = "correct"},
				{text="choice 2 (wrong)", 			result = "wrong"},
				{text="choice 3 (go to start)", 	result = "intro"},
			},
		},
	},

	["correct"] = {
		{text="you selected 1!"},
		{text="that is the \fccorrect one\f7!"},
		"end",
	},
	
	["wrong"] = {
		{text="you selected 2!"},
		{text="that is the \fuwrong one\f7!"},
		function (self)
			if self.box then
				self.box = false
				self:advance("take_box")
			else
				self:advance("no_box")
			end
		end,
	},
	
	["take_box"] = {
		{text="because you selected wrong,\ni am taking your box away"},
		"query",
	},
	
	["no_box"] = {
		{text="loser"},
		"query",
	},
	
	["end"] = {
		{text = "the end!"},
	}
}

return script