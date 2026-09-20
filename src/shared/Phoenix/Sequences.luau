-- Add future exits as another ordered list and register the choice in Policy.
return {
	Normal = {
		{name = "Wake", duration = 0.35},
		{name = "Drain", duration = 1.4},
		{name = "Unlock", duration = 0.35},
		{name = "Open", duration = 0.55},
		{name = "Exit", duration = 0.7},
	},
	Breakout = {
		{name = "Wake", duration = 0.35},
		{name = "Pump", duration = 0.35},
		{name = "Malfunction", duration = 0.6},
		{name = "Pound", duration = 0.55, hit = 1},
		{name = "Pound", duration = 0.55, hit = 2},
		{name = "Pound", duration = 0.55, hit = 3},
		{name = "Burst", duration = 0.4},
		{name = "Exit", duration = 0.8},
	},
}
