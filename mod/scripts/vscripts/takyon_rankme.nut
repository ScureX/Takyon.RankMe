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
	Chat_ServerPrivateMessage(player, "\x1b[34m[RankMe] \x1b[38;2;0;220;30mAll-Time Leaderboard", false)

	int loopAmount = GetConVarInt("rm_cfg_leaderboard_amount") > rm_sortedConfig.len() ? rm_sortedConfig.len() : GetConVarInt("rm_cfg_leaderboard_amount")

	for(int i = 0; i < loopAmount; i++){
		Chat_ServerPrivateMessage(player, format("[%i] %s: [\x1b[38;2;0;220;30m%i/\x1b[38;2;220;20;20m%ix1b[0m] (%f) %i Points", i+1, rm_sortedConfig[i].name, rm_sortedConfig[i].kills, rm_sortedConfig[i].deaths, rm_sortedConfig[i].kills/rm_sortedConfig[i].deaths, rm_sortedConfig[i].points) ,false)
	}
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
						 "void function AddPlayer(string name, string uid, int kills, int deaths, int points){\n" +
						 "RM_PlayerData tmp\ntmp.name = name\ntmp.uid = uid\ntmp.kills = kills\ntmp.deaths = deaths\ntmp.points = points\rm_cfg_players.append(tmp)\n" +
						 "}"

void function RM_SaveConfig(){
	DevTextBufferClear()
	DevTextBufferWrite(RM_HEADER)

	// logic for comparing, only save new vals if higher or not existent
	foreach(RM_PlayerData pd in rm_playerData){ // loop through each player in current match
		if(ShouldSavePlayerInConfig(pd)){
			DevTextBufferWrite(format("AddPlayer(\"%s\", \"%s\", %i, %i, %i)\n", pd.name, pd.uid, pd.kills, pd.deaths, pd.points, pd.track, pd.pointFeed))
		}
		else {
			foreach(RM_PlayerData pdcfg in rm_cfg_players){ // loop through config
				if(pdcfg.uid == pd.uid){ // find players config
					DevTextBufferWrite(format("AddPlayer(\"%s\", \"%s\", %i, %i, %i)\n", pdcfg.name, pdcfg.uid, pdcfg.kills + pd.kills, pdcfg.deaths + pd.deaths, pdcfg.points + pd.points))
					break
				}
			}
		}
	}

    DevTextBufferWrite(RM_FOOTER)

    DevP4Checkout(path)
	DevTextBufferDumpToFile(path)
	DevP4Add(path)
}

/*
 *	CALLBACKS
 */

void function RM_OnPlayerKilled(entity victim, entity attacker, var damageInfo){
	// check if victim is attacker
	if(victim.GetUID() == attacker.GetUID()){
		return
	}

	bool headshot = DamageInfo_GetHitGroup( damageInfo ) == 1  // Head group i think
	bool noscope = attacker.GetZoomFrac() < 0.6
	int dist = ((DamageInfo_GetDistFromAttackOrigin(damageInfo) * 0.01904 * (4/3)) * 3.28084).tointeger()
	int speed = GetPlayerSpeedInKmh(attacker).tointeger()

	int attackerPointsBefore = 0
	int attackerPoints = 0
	int victimPoints = 0

	bool showMsgToVictim = true
	bool showMsgToAttacker = true

	foreach(RM_PlayerData pd in rm_playerData){ // loop through live data
		try{
			if(victim.uid == pd.uid){ // find victim's data
				pd.deaths++
				pd.points -= 3
				victimPoints = pd.points
				showMsgToVictim = pd.track && pd.pointFeed
			}

			if(attacker.uid == pd.uid){ // find attacker's data
				pd.kills++
				attackerPointsBefore = pd.points
				pd.points += 3
				if(noscope && dist >= 50) pd.points += 1 // 1 extra for noscopes above 50m
				if(headshot) pd.points += 1 // 1 extra for headshots
				if(speed > 100) pd.points += 1 // 1 extra for being fast
				if(speed > 200) pd.points += 1 // 1 extra for being fast
				attackerPoints = pd.points
				showMsgToAttacker = pd.track && pd.pointFeed
			}
		}catch(e){}
	}

	// kill modifiers
	string killModifiers = format("[%s%s]", headshot ? "-HS-" : "-", noscope ? "NS-" : "")

	// message players
	if(showMsgToVictim)
		Chat_ServerPrivateMessage(victim, format("%s (%i) got %i Points %s for killing you (%i) (%sm)", attacker.GetPlayerName(), attackerPoints, attackerPoints-attackerPointsBefore, killModifiers, victimPoints, dist), false)
	if(showMsgToAttacker)
		Chat_ServerPrivateMessage(attacker, format("You (%i) got %i Points %s for killing %s (%i) (%sm)", attackerPoints, attackerPoints-attackerPointsBefore, killModifiers, victim.GetPlayerName(), victimPoints, dist), false)
}

void function RM_OnPlayerSpawned(entity player){
	bool found = false
	foreach(RM_PlayerData pd in rm_playerData){
		try{
			if(player.GetPlayerName() == pd.name){
				found = true
			}
		} catch(e){}
	}

	if(!found){
		foreach(RM_PlayerData pd in rm_cfg_players){
			if(player.GetUID == pd.uid){ // if player in config, load player stats
				RM_PlayerData tmp
				tmp.name = player.GetPlayerName()
				tmp.uid = player.GetUID()
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
		rm_playerData.append(tmp)
	}
}

void function RM_OnPlayerDisconnected(entity player){
	for(int i = 0; i < rm_playerData.len(); i++){
		try{
			if(player.GetPlayerName() == rm_playerData[i].name){
				//rm_playerData.remove(i)
			}
		} catch(e){}
	}
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
