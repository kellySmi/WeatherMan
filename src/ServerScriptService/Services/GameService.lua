local repStore = game:GetService("ReplicatedStorage")
local Knit = require(repStore.Packages.Knit)
-- local TableUtil = require(repStore.Packages.TableUtil)
-- local testing = true
local GameService = Knit.CreateService( { 
    Name="GameService", 
    Client = {
        GameEventSignal = Knit.CreateSignal()
    },
    runningGame=false
})
GameService.CurrentGame = {round=1,roundWinners={}}
 GameService.BoardData = {
    boardCoord = {41.25, 25, 105.75}, 
    --  {  stoneName = "field1",
    --  position = {41.25, 25, 105.75},
    --  size = { 14.5, 1, 12.7 },
    --  instances = {},
    --             timer=8
    --         }
    selectionGUIName = "WeatherSelectionGui",
    weather={"Thunderstorms", "Tornado","Snowstorm","Hurricane","Flood","Tsunami","Landslide","Sunny"}
 }
function GameService.TeleportPlayersToGame(player, fromLobby,winnerList)
    local players = GameService.PlayerService.PlayerList
  

    if fromLobby then
        for _, plyer in ipairs(players) do
            local randy = Random.new() -- rando pos for each player.
            -- pick random piece position
            GameService.teleportToPlace(plyer,
                GameService.BoardData.boardCoord[1].instances[randy:NextInteger(1,#GameService.BoardData.stones[1].instances)].position)
        end
    else
        -- just do the winner of the last round back to the winners spawn plate
        local  spwnPos = { -51.756, 68.399, -46.615}
       -- for _, plyr in ipairs(winnerList) do
           -- if winnerList[1] == player.Name then
                GameService.teleportToPlace(winnerList[1],spwnPos)
          --  end
        -- end
    end
end
function GameService.teleportToPlace(player, dest)
    
    local newDest = Vector3.new(dest[1], dest[2], dest[3]) 
    player.Character:MoveTo(newDest)
end

function GameService.Client:PlayerAdded(player)
    -- a player has entered the game, check if a game is running
    -- if no running game then start game now with all players
    if not GameService.runningGame then
       GameService.StartGame(player)
        -- print("the game should be running continuously until last player leaves")
    end
   
end

function GameService.StartGame(player)

    -- local update = {event="startTimer", allPlayers=true, timer=5}
     GameService.runningGame = true
     -- begin game loop 
     -- teleport all players to terrain
     while GameService.runningGame do
       
        -- show GUI to make selection
        -- show timer while showing selection GUI 
        -- hide GUI at end of timer recording all selections
        -- display weather 
        -- kill players with incorrect selections teleport back to lobby
        -- repeate for winners

    --    GameService.startRound(player) 
    --     if #GameService.CurrentGame.roundWinners <= 1 then
    --         GameService.endRound(player)
    --         task.wait(2)
    --         if #GameService.CurrentGame.roundWinners == 1 then
    --             GameService.TeleportPlayersToGame(player,false,GameService.CurrentGame.roundWinners)
    --         end
    --         GameService.ClearBoard()
    --         GameService.endGame(player)
    --     else 
    --         GameService.endRound(player)
    --         task.wait(2)
    --         GameService.FreezePlayers(true)
    --       --  print("clearing board")
    --         GameService.ClearBoard()
    --         GameService.DrawBoard()
    --         GameService.FreezePlayers(false)
    --         GameService.CurrentGame.roundWinners = {}
    --     end
     end
    -- -- print("ReStarting a new game now")
    -- -- task.wait(2)
    -- GameService.StartGame(player)
 
end
function GameService.endRound(player)
    GameService:UpdateGameEventSignal(player,{event="endRound", allPlayers=true})
end

function GameService.endGame(player)
    -- we have a winner so put up their name in the status gui
    GameService.runningGame = false
    -- check if there is a winner other wise send out No winner message
    local endMess = ""
    if #GameService.CurrentGame.roundWinners == 1 then
        endMess = GameService.CurrentGame.roundWinners[1].Name.." is the WINNER!"
    else
        endMess = "There are no winners."
    end
    GameService:UpdateGameEventSignal(player,{event="endGame",allPlayers=true, message=endMess})
    task.wait(2) 
    GameService.CurrentGame.roundWinners = {}
end

function GameService.startRound(player)
    local rando = Random.new()
    local win = rando:NextInteger(1,#GameService.BoardData.colors)

    local winningColor = GameService.BoardData.colors[win]
    -- show timer GUI and start timer
    local update = {event="showWinnerStartCountdown", allPlayers=true, winner=winningColor, timer=5}
    -- fire game event signal to start the round, the client should show a 5 sec timer display.
    GameService:UpdateGameEventSignal(player, update)
    -- do round countdown here like the start countdown
    local ix = 0
    local tmr = 5
    while ix < tmr do
        update.event = "updateRoundCountdown"
        update.timer = (tmr - ix)
        GameService:UpdateGameEventSignal(player, update)
        task.wait(1)
        ix = ix + 1
    end
    update.timer = 0
    GameService:UpdateGameEventSignal(player, update)

    -- drop the parts from here , unanchor all parts that don't have the winning color
    local gamePieces = workspace.GamePieces:GetChildren()
    for _, piece in ipairs(gamePieces) do
        if piece.BrickColor.Name ~= winningColor then
            piece.Anchored = false
        end
    end
    GameService.getRoundWinners()
end
function GameService.showStartCountdown(player,update)
    -- we will loop here and send the countdown to the ui to keep all players in sync
    local i = 0
    local ctr = update.timer
    while i < ctr do
      --  print(5-i)
        update.event = "startTimer"
        GameService:UpdateGameEventSignal(player, update) 
        if i == 3 then
            GameService.TeleportPlayersToGame(player, true)
        end
        task.wait(1)
        i = i + 1
        update.timer = (ctr - i)
    end
end
function GameService.getRoundWinners()
    -- local winnersList = {}
    local allPlayers = GameService.PlayerService.PlayerList
    for _, player in ipairs(allPlayers) do
        
        -- this is the height of the board so if you are above it or below it then you didn't make it
        task.wait(2)
       --  print("Y",player.Character.PrimaryPart.CFrame.p.Y)
        if player.Character.PrimaryPart and (player.Character.PrimaryPart.CFrame.p.Y < 30 and player.Character.PrimaryPart.CFrame.p.Y > 26) then
            GameService.CurrentGame.roundWinners[#GameService.CurrentGame.roundWinners+1] = player
        end
    end
    -- print(winnersList)
   -- return winnersList
end
-- function GameService.FreezePlayers(freeze)
--     for _,player in pairs(GameService.CurrentGame.roundWinners) do
--         player.Character.PrimaryPart.Anchored = freeze
--     end
-- end
-- function GameService.ClearBoard()
--     local gamePieces = workspace.GamePieces:GetChildren()
--     for _, piece in ipairs(gamePieces) do
--         piece.Anchored = false
--        piece:Destroy()
--     end
-- end

function GameService:UpdateGameEventSignal(player, update) 
    self.Client.GameEventSignal:Fire(player,update)
end

function GameService.KnitStart()
    GameService.PlayerService = Knit.GetService("PlayerService")
    print("Starting Game service")

end

return GameService