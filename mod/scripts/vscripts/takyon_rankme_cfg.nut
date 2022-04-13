global function RM_CfgInit
global array<RM_PlayerData> rm_cfg_players = []

void function RM_CfgInit(){
rm_cfg_players.clear()
AddPlayer("asdasd", "712398713", 123, 123, int 1123, true, true)
AddPlayer("fghjgjf", "123123123", 13, 13, int 123, true, true)
AddPlayer("asq3werq", "23423423423", 13, 23, int 113, true, true)
}

void function AddPlayer(string name, string uid, int kills, int deaths, int points, bool track, bool pointFeed){
RM_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.kills = kills
tmp.deaths = deaths
tmp.points = points
tmp.track = track
tmp.pointFeed = pointFeed
rm_cfg_players.append(tmp)
}