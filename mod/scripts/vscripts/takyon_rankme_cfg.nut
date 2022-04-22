global function RM_CfgInit
global array<RM_PlayerData> rm_cfg_players = []

void function RM_CfgInit(){
rm_cfg_players.clear()
AddPlayer("Takyon_Scure", "1006880507304", 82, 31, 21217, true, true)
AddPlayer("Robertineau", "2829239308", 0, 2, 994, true, true)
AddPlayer("TAAWERZ", "1008142882244", 12, 15, 992, true, true)
AddPlayer("darthelmo10", "1009099551543", 35, 16, 1072, true, true)
AddPlayer("itsAETROX", "1008736605593", 205, 63, 1456, false, true)
AddPlayer("LUCApex1", "1009742204748", 18, 33, 957, false, true)
AddPlayer("AshesOfMemories", "2250333402", 9, 14, 988, true, true)
AddPlayer("Gr3nKnight", "1014114775531", 48, 56, 981, true, true)
AddPlayer("Swagboss_312", "1007953629777", 1, 3, 995, true, true)
AddPlayer("var-username", "1000672976295", 5, 5, 1000, true, true)
AddPlayer("Jakanader", "1007938662987", 11, 9, 1008, false, true)
AddPlayer("Tamukobreeze", "1011977239236", 2, 7, 986, false, true)
AddPlayer("USchana", "1007973879393", 1, 0, 1003, true, true)
AddPlayer("Mehoymenoy25", "1007578198032", 19, 34, 958, true, true)
AddPlayer("IDKCosmic", "1008951483027", 2, 0, 1006, true, true)
AddPlayer("Nestormaverick", "1000504566715", 2, 3, 998, true, true)
AddPlayer("Miscellaniious", "1013115392455", 0, 2, 994, true, true)
AddPlayer("SpookBoi445", "1010492448076", 0, 2, 994, true, true)
AddPlayer("Rozeiki", "1008922361376", 1, 2, 997, true, true)
AddPlayer("edsonsoto04", "1002605720941", 0, 1, 997, true, true)
AddPlayer("ArKKestral", "1006322919372", 9, 29, 942, true, true)
AddPlayer("hzr808", "1007110150465", 103, 122, 949, true, true)
AddPlayer("Unsober808", "1010655133468", 33, 137, 694, true, true)
}

void function AddPlayer(string name, string uid, int kills, int deaths, int points, bool track, bool pointFeed){
RM_PlayerData tmp;
tmp.name = name;
tmp.uid = uid;
tmp.kills = kills;
tmp.deaths = deaths;
tmp.points = points;tmp.track = track;
tmp.pointFeed = pointFeed;
rm_cfg_players.append(tmp);
}