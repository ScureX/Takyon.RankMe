global function RM_CfgInit
global array<RM_PlayerData> rm_cfg_players = []

void function RM_CfgInit(){
rm_cfg_players.clear()
}

void function AddPlayer(string name, string uid, int kills, int deaths, int points){
RM_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.kills = kills
tmp.deaths = deaths
tmp.points = points
rm_cfg_players.append(tmp)
}