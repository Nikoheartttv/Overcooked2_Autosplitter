state("Overcooked2") 
{
	int TotalBaseScore: "mono.dll", 0x1f798c, 0xc, 0x1c0, 0x74, 0x8c, 0x38, 0x8;
	int TotalTipsScore: "mono.dll", 0x1f798c, 0xc, 0x1c0, 0x74, 0x8c, 0x38, 0xc;
	int TotalTimeExpireDeductions:  "mono.dll", 0x1f798c, 0xc, 0x1c0, 0x74, 0x8c, 0x38, 0x18;
	int ScreenTransitionState: "UnityPlayer.dll", 0xFFB648, 0x18, 0x0, 0x8, 0x20, 0x360;
}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "Overcooked! 2";
	vars.Helper.LoadSceneManager = true;
	vars.Helper.AlertLoadless();

	var SceneLabels = new Dictionary<string, string>() {
		{ "s_tutorial_01", "Tutorial 1" },
		{ "s_sushi_1_1", "1-1" },
		{ "s_sushi_1_2", "1-2" },
		{ "s_sushi_s1_3", "1-3" },
		{ "s_sushi_1_4", "1-4" },
		{ "s_balloon_1_5", "1-5" },
		{ "s_dynamic_Stage_01", "1-6" },
		{ "s_rapids_2_1", "2-1" },
		{ "s_balloon_2_3", "2-2" },
		{ "s_balloon_2_2", "2-3" },
		{ "s_mine_2_4", "2-4" },
		{ "s_mine_2_5", "2-5" },
		{ "s_mine_2_6", "2-6" },
		{ "s_wizard_3_1", "3-1" },
		{ "s_wizard_5_5", "3-2" },
		{ "s_wizard_3_2", "3-3" },
		{ "s_wizard_3_3", "3-4" },
		{ "s_rapids_3_5", "3-5" },
		{ "s_dynamic_stage_02", "3-6" },
		{ "s_sushi_4_1", "4-1" },
		{ "s_rapids_4_2A", "4-2" },
		{ "s_mine_4_3", "4-3" },
		{ "s_mine_5_3", "4-4" },
		{ "s_sushi_4_5", "4-5" },
		{ "s_mine_4_6", "4-6" },
		{ "MovingPlatform4", "5-1" },
		{ "s_balloon_5_2", "5-2" },
		{ "MovingPlatform5", "5-3" },
		{ "s_wizard_school_3_4", "5-4" },
		{ "MovingPlatform2", "5-5" },
		{ "s_dynamic_stage_03", "5-6" },
		{ "s_balloon_6_4", "6-1" },
		{ "s_space_6_2", "6-2" },
		{ "s_sushi_5_1", "6-3" },
		{ "MovingPlatform3", "6-4" },
		{ "s_space_6_5_GTG", "6-5" },
	};

	settings.Add("split_scene", true, "Split on completing scene:");
	foreach(var scene in SceneLabels.Keys)
	{
		settings.Add(scene, true, SceneLabels[scene], "split_scene");
	}

	vars.xml = System.Xml.Linq.XDocument.Load(@"Components/Overcooked2.Data.xml").Element("Data");
	
	settings.Add("Stars", true, "Required Stars Run");
	settings.Add("1S", true, "1 Star", "Stars");
	settings.Add("2S", false, "2 Stars", "Stars");
	settings.Add("3S", false, "3 Stars", "Stars");
	settings.Add("4S", false, "4 Stars", "Stars");
}

init
{
	// Sets LevelScore to 0 upon level entry, updates when Total core from state updates
	vars.loadingState = false;
	vars.LevelPointer = IntPtr.Zero;
	vars.RequiredScore = -1;
	current.TotalScore = 0;
	current.LevelScore = 0;

	vars.LevelsComplete = new MemoryWatcherList();
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => 
	{
		var T17FrontendFlow = mono["T17FrontendFlow"];
		var SelectSaveDialog = mono["SelectSaveDialog"];
		var SSElement = mono["SaveSlotElement"];
		var T17OnlineClientUserSystem = mono["Team17.Online.ClientUserSystem"];

		vars.Helper["Slot_01"] = mono.Make<bool>(T17FrontendFlow, "s_Instance", "m_saveDialog", SelectSaveDialog["m_saveElements"], 0x10, SSElement["m_bTriggeredLoad"]);
		vars.Helper["Slot_02"] = mono.Make<bool>(T17FrontendFlow, "s_Instance", "m_saveDialog", SelectSaveDialog["m_saveElements"], 0x14, SSElement["m_bTriggeredLoad"]);
		vars.Helper["Slot_03"] = mono.Make<bool>(T17FrontendFlow, "s_Instance", "m_saveDialog", SelectSaveDialog["m_saveElements"], 0x18, SSElement["m_bTriggeredLoad"]);
		vars.Helper["LobbyCount"] = mono.Make<int>(T17OnlineClientUserSystem, "m_Users", 0x10); // 0x10 = FastList._size
			
		return true;
    });
}

update
{
	current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

	if(current.activeScene != old.activeScene) vars.Log("active: Old: \"" + old.activeScene + "\", Current: \"" + current.activeScene + "\"");
	if(current.loadingScene != old.loadingScene) vars.Log("loading: Old: \"" + old.loadingScene + "\", Current: \"" + current.loadingScene + "\"");
	if(current.ScreenTransitionState != old.ScreenTransitionState) vars.Log("ScreenTransitionState: " + current.ScreenTransitionState);

	vars.LevelsComplete.UpdateAll(game);

	if (current.ScreenTransitionState != old.ScreenTransitionState && current.ScreenTransitionState == 3) vars.loadingState = (current.activeScene == "Loading");
	
	if (vars.LevelPointer == IntPtr.Zero && (current.activeScene == "WorldMap" || current.activeScene == "WorldMap_DLC05"))
	{
		var dptr = new DeepPointer("UnityPlayer.dll", 0xfdc8bc, 0x38, 0x54, 0xc, 0xc8, 0x18, 0x18, 0x1c, 0x8, 0x0);
		IntPtr iptr = IntPtr.Zero;
		if (dptr.DerefOffsets(game, out iptr)) vars.LevelPointer = iptr;
		
		if (vars.LevelPointer != IntPtr.Zero)
		{
			int length = game.ReadValue<int>((IntPtr)vars.LevelPointer + 0xc);
			for (int i = 0; i < length; i++)
			{
				dptr = new DeepPointer((IntPtr)vars.LevelPointer + 0x10 + (0x4 * i), 0);
				dptr.DerefOffsets(game, out iptr);

				int levelId = game.ReadValue<int>(iptr + 0x8);
				vars.LevelsComplete.Add(new MemoryWatcher<bool>(iptr + 0xc){ Name = levelId.ToString() });
			}
			vars.Log("Watchers Initialised!");
		}
	}
	
	if (current.activeScene == "WorldMap" && vars.RequiredScore != -1) vars.RequiredScore = -1;
	else if (settings.ContainsKey(current.activeScene) && vars.RequiredScore == -1)
	{
		var levels = vars.xml.Element("Levels").Elements("Level");

		var players = current.LobbyCount;

		var stars = 1;
		if (settings["2S"]) stars = 2;
		if (settings["3S"]) stars = 3;
		if (settings["4S"]) stars = 4;
		
		foreach(var level in levels) 
			if (level.Attribute("ID").Value == current.activeScene)
			{
				foreach(var score in level.Element("Scores").Elements("Score"))
				{
					if (Int32.Parse(score.Attribute("Players").Value) == players
						&& Int32.Parse(score.Attribute("Star").Value) == stars)
					{
						vars.RequiredScore = Int32.Parse(score.Attribute("Value").Value);
						vars.Log("Required Score set to " + vars.RequiredScore.ToString());
						break;
					}
				}
				break;
			}
	}

	current.TotalScore = current.TotalBaseScore + current.TotalTipsScore - current.TotalTimeExpireDeductions;
	if (current.TotalScore != old.TotalScore) 
	{
		current.LevelScore = current.TotalScore;
	}

	if (old.activeScene != current.activeScene && settings.ContainsKey(current.activeScene)) current.LevelScore = 0;


}

start
{
	return old.activeScene == "Loading"
	    && current.activeScene == "s_tutorial_01";
}

onStart
{
	vars.loadingState = false;
	vars.LevelPointer = IntPtr.Zero;
	vars.RequiredScore = -1;
}

split
{
	if (vars.LevelsComplete.Count > 0 && vars.LevelsComplete["36"].Changed && vars.LevelsComplete["36"].Current) return true;
	return old.activeScene != current.activeScene
		&& current.LevelScore >= vars.RequiredScore
		&& settings.ContainsKey(old.activeScene) && settings[old.activeScene];
}

isLoading
{
	return vars.loadingState;
	// return current.activeScene == "Loading" || current.ScreenTransitionState > 0;
	// return current.activeScene != current.loadingScene;
}
