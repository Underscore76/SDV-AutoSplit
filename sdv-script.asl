state("Stardew Valley")
{
	
}
init
{
	vars.aslName = "StardewValley";
	// pulled from: https://raw.githubusercontent.com/PrototypeAlpha/AmnesiaASL/master/AmnesiaTDD.asl
	if(timer.CurrentTimingMethod == TimingMethod.RealTime)
	{		
		var timingMessage = MessageBox.Show(
			"This game uses Game Time (time without loads) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (time INCLUDING loads).\n"+
			"Would you like the timing method to be set to Game Time for you?",
			vars.aslName+" | LiveSplit",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		if (timingMessage == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
	
	print("Running signature scans...");
	IntPtr ptr;
	int Game1_game1 = 0;
	IntPtr global_ptr = IntPtr.Zero;
	// basic loop layout from: https://raw.githubusercontent.com/jbzdarkid/Autosplitters/master/LiveSplit.FEZ.asl
	foreach(var page in game.MemoryPages()) 
	{
		var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
		
		// SaveGameMenu.Dispose
		/*
		{
			ptr = scanner.Scan(new SigScanTarget(2,
			"8B 15 ?? ?? ?? ??", // mov edx, [target]
			"C6 82 B0 00 00 00 00", // test 
			"C3" // ret
			));
			if (ptr != IntPtr.Zero) 
			{
				global_ptr = (IntPtr)memory.ReadValue<int>(ptr);
				print("global_ptr: 0x" + global_ptr.ToString("X"));
			}
		}
		*/
		
		// Game1._update
		{
			ptr = scanner.Scan(new SigScanTarget(10,
			"8B 01", // mov eax, [ecx]
			"8B 40 40", // move eax, [eax + 40]
			"FF 50 10", // call dword ptr [eax + 10]
			"83 3D ?? ?? ?? ?? 00", // cmp dword ptr [target], 00
			"74 65" // je _update+1B4
			));
			if (ptr != IntPtr.Zero) 
			{
				global_ptr = (IntPtr)memory.ReadValue<int>(ptr) - 0x28;
				print("global_ptr: 0x" + global_ptr.ToString("X"));
			}
		}
	}
	
	if (global_ptr == IntPtr.Zero)
	{
		throw new Exception("Couldn't find Stardew Valley!");
	}
	
	Game1_game1 = memory.ReadValue<int>((IntPtr)global_ptr);
	print("Found Game1.game1 at 0x" + Game1_game1.ToString("X"));
	
	vars.Game1_isSaving = Game1_game1 + 0xB0;
	vars.Game1_newDayTask = global_ptr + 0x28;
	vars.Game1_activeClickableMenu = global_ptr - 0x68;
	vars.isSaving = false;
	vars.newDayTask = 0;
	vars.loading = false;
}

update
{
	vars.isSaving = memory.ReadValue<bool>((IntPtr)vars.Game1_isSaving);
	vars.newDayTask = memory.ReadValue<int>((IntPtr)vars.Game1_newDayTask);
	IntPtr menu = (IntPtr)memory.ReadValue<int>((IntPtr)vars.Game1_activeClickableMenu);
	bool menuIsTitle = false;
	if (menu != IntPtr.Zero)
	{
		IntPtr vtable = (IntPtr)memory.ReadValue<int>(menu);
		uint startupMessageColor = memory.ReadValue<uint>(menu+0xEC);
		int menu_size = memory.ReadValue<int>(vtable + 0x4);
		// the startup menu uses a deepskyblue which is ultra specific/unchanging.
		if (menu_size == 244 && startupMessageColor == 4294950656)
		{
			menuIsTitle = true;
		}
	}	
	
	vars.loading = menuIsTitle || vars.isSaving || (vars.newDayTask != 0);
	//print("LS_DEBUG:" + vars.isSaving.ToString() + ":" + vars.newDayTask.ToString() + "->" + vars.loading.ToString());
}

isLoading
{
	return vars.loading;
}
