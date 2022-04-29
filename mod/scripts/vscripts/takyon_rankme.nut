global function RankMeInit

global struct RM_PlayerData{
	string name 
	string uid
	int kills = 0
	int deaths = 0
	int points = 1000
	bool track = true // should track stats
	bool pointFeed = true // should send the kill msg with points n all
}

const string path = "../R2Northstar/mods/Takyon.RankMe/mod/scripts/vscripts/takyon_rankme_cfg.nut" // where the config is stored
array<RM_PlayerData> rm_playerData = [] // data from current match

void function RankMeInit(){
	AddCallback_OnReceivedSayTextMessage(RM_ChatCallback)
	
	AddCallback_OnPlayerRespawned(RM_OnPlayerSpawned)
    AddCallback_OnClientDisconnected(RM_OnPlayerDisconnected)
	AddCallback_OnPlayerKilled(RM_OnPlayerKilled)
	//AddCallback_GameStateEnter(eGameState.Postmatch, TS_Postmatch)
}

void function RM_LeaderBoard(entity player){
	RM_CfgInit() // load config

	array<RM_PlayerData> rm_sortedConfig = rm_cfg_players // sort config in new array to not fuck with other shit
	rm_sortedConfig.sort(RankMeSort)
	Chat_ServerPrivateMessage(player, "\x1b[34m[RankMe] \x1b[38;2;0;220;30mTop Leaderboard \x1b[0m[" + rm_sortedConfig.len() + " Ranked]", false)

	int loopAmount = GetConVarInt("rm_cfg_leaderboard_amount") > rm_sortedConfig.len() ? rm_sortedConfig.len() : GetConVarInt("rm_cfg_leaderboard_amount")

	for(int i = 0; i < loopAmount; i++){
		int deaths = rm_sortedConfig[i].deaths == 0 ? 1 : rm_sortedConfig[i].deaths // aboid division through 0
		string kd = format("%.2f", rm_sortedConfig[i].kills*1.0/deaths*1.0)
		Chat_ServerPrivateMessage(player, format("[%i] %s: [\x1b[38;2;0;220;30m%i/\x1b[38;2;220;20;20m%i\x1b[0m] (%s) \x1b[38;2;0;220;30m%i \x1b[0mPoints", i+1, rm_sortedConfig[i].name, rm_sortedConfig[i].kills, rm_sortedConfig[i].deaths, kd, rm_sortedConfig[i].points) ,false)
	}
}

void function RM_TrackToggle(entity player){
	foreach(RM_PlayerData pd in rm_playerData){ // loop through each player in current match
		if(pd.uid == player.GetUID()){ // player in live match is in cfg // REM 
			pd.track = !pd.track
			Chat_ServerPrivateMessage(player, format("\x1b[34m[RankMe]\n\x1b[0mTracking of your points is now %s. Settings will apply on map-reload", pd.track ? "enabled" : "disabled"), false)
			RM_SaveConfig()
		}
	}
}

void function RM_PointFeedToggle(entity player){
	foreach(RM_PlayerData pd in rm_playerData){ // loop through each player in current match
		if(pd.uid == player.GetUID()){ // player in live match is in cfg // REM 
			pd.pointFeed = !pd.pointFeed
			Chat_ServerPrivateMessage(player, format("\x1b[34m[RankMe]\n\x1b[0mPointfeed is now %s. Settings will apply on map-reload", pd.pointFeed ? "enabled" : "disabled"), false)
			RM_SaveConfig()
		}
	}
}

void function RM_Rank(entity player){
	RM_CfgInit() // load config

	array<RM_PlayerData> rm_sortedConfig = rm_cfg_players // sort config in new array to not fuck with other shit
	rm_sortedConfig.sort(RankMeSort)

	for(int i = 0; i < rm_sortedConfig.len(); i++){
		if(rm_sortedConfig[i].uid == player.GetUID()){
			int deaths = rm_sortedConfig[i].deaths == 0 ? 1 : rm_sortedConfig[i].deaths // aboid division through 0
			string kd = format("%.2f", rm_sortedConfig[i].kills*1.0/deaths*1.0)
			Chat_ServerPrivateMessage(player, format("[%i/%i] %s: [\x1b[38;2;0;220;30m%i/\x1b[38;2;220;20;20m%i\x1b[0m] (%s) \x1b[38;2;0;220;30m%i \x1b[0mPoints", i+1, rm_sortedConfig.len(), rm_sortedConfig[i].name, rm_sortedConfig[i].kills, rm_sortedConfig[i].deaths, kd, rm_sortedConfig[i].points) ,false)
			break
		}
	}
}

void function RM_Help(entity player){
	Chat_ServerPrivateMessage(player, "\x1b[34m[RankMe]\n\x1b[0mLeaderboard: !top\nYour Rank: !rank\nToggle Tracking: !track\nToggle Points-Msg: !pointfeed",false)
}

/*
 *	CHAT COMMANDS
 */

ClServer_MessageStruct function RM_ChatCallback(ClServer_MessageStruct message) {
    string msg = message.message.tolower()
    // find first char -> gotta be ! to recognize command
    if (format("%c", msg[0]) == "!") {
        // command
        msg = msg.slice(1) // remove !
        array<string> msgArr = split(msg, " ") // split at space, [0] = command
        string cmd
        
        try{
            cmd = msgArr[0] // save command
        }
        catch(e){
            return message
        }

        // command logic
		if(cmd == "top"){
			RM_LeaderBoard(message.player)
		} 
		else if(cmd == "track"){
			RM_TrackToggle(message.player)
		}
		else if(cmd == "pointfeed"){
			RM_PointFeedToggle(message.player)
		}
		else if(cmd == "rankme"){
			RM_Help(message.player)
		}
		else if(cmd == "rank"){
			RM_Rank(message.player)
		}
    }
    return message
}

/*
 *	CONFIG
 */

const string RM_HEADER = "global function RM_CfgInit\n" +
						 "global array<RM_PlayerData> rm_cfg_players = []\n\n" +
						 "void function RM_CfgInit(){\n" +
						 "rm_cfg_players.clear()\n"

const string RM_FOOTER = "}\n\n" +
						 "void function AddPlayer(string name, string uid, int kills, int deaths, int points, bool track, bool pointFeed){\n" +
						 "RM_PlayerData tmp;\ntmp.name = name;\ntmp.uid = uid;\ntmp.kills = kills;\ntmp.deaths = deaths;\ntmp.points = points;\rtmp.track = track;\ntmp.pointFeed = pointFeed;\nrm_cfg_players.append(tmp);\n" +
						 "}"

void function RM_SaveConfig(){
	RM_CfgInit()

	array<RM_PlayerData> offlinePlayersToSave = []

	foreach(RM_PlayerData pdcfg in rm_cfg_players){ // loop through each player in cfg
		bool found = false
		foreach(RM_PlayerData pd in rm_playerData){ // loop through each player in current match
			if(pdcfg.uid == pd.uid){ // player in live match is in cfg // REM 
				found = true
			}
		}

		if(!found){
			offlinePlayersToSave.append(pdcfg)
		}
	}
	
	// merge live and offline players
	array<RM_PlayerData> allPlayersToSave = []
	allPlayersToSave.extend(rm_playerData)
	allPlayersToSave.extend(offlinePlayersToSave)

	// write to buffer
	DevTextBufferClear()
	DevTextBufferWrite(RM_HEADER)

	foreach(RM_PlayerData pd in allPlayersToSave){
		DevTextBufferWrite(format("AddPlayer(\"%s\", \"%s\", %i, %i, %i, %s, %s)\n", pd.name, pd.uid, pd.kills, pd.deaths, pd.points, pd.track.tostring(), pd.pointFeed.tostring()))	
	}
	
    DevTextBufferWrite(RM_FOOTER)

    DevP4Checkout(path)
	DevTextBufferDumpToFile(path)
	DevP4Add(path)
	print("[RankMe] Saving config at " + path)
}

/*
 *	CALLBACKS
 */

void function RM_OnPlayerKilled(entity victim, entity attacker, var damageInfo){
	// death pits, etc where either one isnt a player
	if(!attacker.IsPlayer() || !victim.IsPlayer()){
		return
	}

	// check if victim is attacker 
	if(victim.GetUID() == attacker.GetUID()){
		//return // REM
	}

	bool headshot = DamageInfo_GetHitGroup( damageInfo ) == 1  // Head group i think
	bool noscope = attacker.GetZoomFrac() < 0.2 // leave a bit of room i guess, not workin on longer shots tho
	
	int dist = ((DamageInfo_GetDistFromAttackOrigin(damageInfo) * 0.01904 * (4/3)) * 3.28084).tointeger()
	int speed = GetPlayerSpeedInKmh(attacker).tointeger()

	int attackerPointsBefore = 0
	int attackerPoints = 0
	int victimPoints = 0

	int pointExchange = 0

	bool showMsgToVictim = true
	bool showMsgToAttacker = true
	bool victimTrack = true

	// get elo info for point calculation
	foreach(RM_PlayerData pd in rm_playerData){ // loop through live data
		try{
			if(victim.GetUID() == pd.uid) // find victim's data // REM
				victimPoints = pd.points

			if(attacker.GetUID() == pd.uid){ // find attacker's data // REM
				attackerPoints = pd.points
				attackerPointsBefore = pd.points
			}
		
		}catch(e){print("[RankMe] couldnt save points: " + e); return;}
	}

	int diff = attackerPoints - victimPoints 

	// winner has less points
	if(diff <= -1200) // winner has 1200 points less
		pointExchange = 8
	else if(diff <= -350) // winner has 350 to 1200 points less
		pointExchange = 7
	else if(diff < 0) // winner has 1 to 350 points less
		pointExchange = 6
	
	// winner has more points
	else if(diff >= 1200) // winner has 1200 points more
		pointExchange = 3
	else if(diff >= 350) // winner has 350 to 1200 points more
		pointExchange = 4
	else if(diff >= 0) // winner has 0 to 350 points more
		pointExchange = 5
		
	foreach(RM_PlayerData pd in rm_playerData){ // loop through live data
		try{
			// actually add the points
			if(victim.GetUID() == pd.uid){ // find victim's data // REM
				showMsgToVictim = pd.track && pd.pointFeed
				victimTrack = pd.track
				if(pd.track){
					pd.deaths++
					pd.points -= pointExchange
					victimPoints = pd.points
				}
			}

			if(attacker.GetUID() == pd.uid){ // find attacker's data // REM
				showMsgToAttacker = pd.track && pd.pointFeed
				if(pd.track){
					pd.kills++
					attackerPointsBefore = pd.points
					pd.points += pointExchange
					if(noscope && dist >= 50) pd.points += 1 // 1 extra for noscopes above 50m
					if(headshot) pd.points += 1 // 1 extra for headshots
					if(speed > 100) pd.points += 1 // 1 extra for being fast
					if(speed > 200) pd.points += 1 // 1 extra for being fast
					attackerPoints = pd.points
				}
			}
		}catch(e){print("[RankMe] couldnt save points: " + e)}
	}

	// kill modifiers
	string killModifiers = format("[%s%s]", headshot ? "-HS-" : "-", noscope ? "NS-" : "")
	
	// message players
	if(showMsgToVictim){
		Chat_ServerPrivateMessage(victim, format("%s (\x1b[38;2;0;220;30m%i\x1b[0m) got \x1b[38;2;0;220;30m%i \x1b[0mPoints \x1b[38;2;220;20;20m%s \x1b[0mfor killing %s (\x1b[38;2;0;220;30m%i\x1b[0m) (\x1b[38;2;220;20;20m-%i\x1b[0m) |  (\x1b[38;2;0;220;30m%im\x1b[0m)", 
		attacker.GetPlayerName(), attackerPoints, attackerPoints-attackerPointsBefore, killModifiers, victim.GetPlayerName(), victimPoints, pointExchange, dist), false)
	}
		
	if(showMsgToAttacker)
		Chat_ServerPrivateMessage(attacker, format("%s (\x1b[38;2;0;220;30m%i\x1b[0m) got \x1b[38;2;0;220;30m%i \x1b[0mPoints \x1b[38;2;220;20;20m%s \x1b[0mfor killing %s (\x1b[38;2;0;220;30m%i\x1b[0m) (\x1b[38;2;220;20;20m-%i\x1b[0m) | (\x1b[38;2;0;220;30m%im\x1b[0m)", 
		attacker.GetPlayerName(), attackerPoints, attackerPoints-attackerPointsBefore, killModifiers, victim.GetPlayerName(), victimPoints, victimTrack ? pointExchange : 0, dist), false)
	
	RM_SaveConfig()
}

void function RM_OnPlayerSpawned(entity player){
	foreach(RM_PlayerData pd in rm_playerData){ // check if in live data
		try{
			if(player.GetUID() == pd.uid){ // REM
				return
			}
		} catch(e){print("[RM] " + e)}
	}
	RM_CfgInit()
	foreach(RM_PlayerData pd in rm_cfg_players){
		if(player.GetUID() == pd.uid){ // if player in config, load player stats // REM
			RM_PlayerData tmp
			tmp.name = player.GetPlayerName() // maybe they changed their name? idk just gonna do it like this
			tmp.uid = pd.uid
			tmp.kills = pd.kills
			tmp.deaths = pd.deaths
			tmp.points = pd.points
			tmp.track = pd.track
			tmp.pointFeed = pd.pointFeed
			rm_playerData.append(tmp)
			return
		}
	}
	// player not yet in config
	RM_PlayerData tmp
	tmp.name = player.GetPlayerName()
	tmp.uid = player.GetUID() 
	tmp.points = 1000
	rm_playerData.append(tmp)
}

void function RM_OnPlayerDisconnected(entity player){
	/*for(int i = 0; i < rm_playerData.len(); i++){
		try{
			if(player.GetPlayerName() == rm_playerData[i].name){ // REM
				//rm_playerData.remove(i)
			}
		} catch(e){}
	}*/
}

/*
 *	HELPER FUNCTIONS
 */

// true if not in cfg, false if in config
bool function ShouldSavePlayerInConfig(RM_PlayerData pd){ 
	foreach(RM_PlayerData pdcfg in rm_cfg_players){ // loop through config
		if(pdcfg.uid == pd.uid){ // find players config
			return false // is in config
		}
	}
	return true // player not yet in config
}

int function RankMeSort(RM_PlayerData data1, RM_PlayerData data2){
  if ( data1.points == data2.points )
    return 0
  return data1.points < data2.points ? 1 : -1
}

float function GetPlayerSpeedInKmh(entity player){
	vector playerVelV = player.GetVelocity()
    return sqrt(playerVelV.x * playerVelV.x + playerVelV.y * playerVelV.y) * (0.274176/3)
}
