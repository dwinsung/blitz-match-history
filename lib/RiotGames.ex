defmodule RiotGames do
  use HTTPoison.Base

  @expected_fields ~w(
   id accountId puuId name profileIconId revisionDate
   summonerLevel matches participantIdentities gameId
  )
  def process_request_url(url) do
    "https://na1.api.riotgames.com/" <> url
  end

  def process_response_body(body) do
    body
    |> Poison.decode!
    |> Map.take(@expected_fields)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  end
  def get_api_key() do
    api_key=IO.puts ("What is your api key?")|>String.trim
  end
  ##gets specific account ID for subject summoner
  def get_summoner_accountID(name,api_key) do
    summoner_info = RiotGames.get!("lol/summoner/v4/summoners/by-name/#{name}?api_key=#{api_key}")
    status_code = summoner_info.status_code
    case status_code do
      429 ->
      IO.puts("Rate Limit reached, too many requests. Will re-execute in 10 seconds")
      :timer.sleep(10000)
      get_summoner_accountID(name,api_key)
      404 ->
      name = IO.gets("Summoner does not exist. Please enter a proper summoner name now: ")|>String.trim
      get_summoner_accountID(name,api_key)
      403 ->
      IO.puts("API key is not working properly. The script will error out; verify that the API key is correct in the script in the find_recently_played_with_matches function.")
      200 ->
      account_id =elem(List.first(summoner_info.body),1)
    end
  end

  ##gets full list of matches for said sumoner
  def get_summoner_matchlist(account_id, api_key) do
    :timer.sleep(400)
    matchreq = RiotGames.get!("lol/match/v4/matchlists/by-account/#{account_id}?endIndex=5&api_key=#{api_key}")
    case matchreq.status_code do
      200 ->
      matchlist_info = matchreq.body
      match_list = elem(List.first(matchlist_info), 1)
      429 ->
      IO.gets("Rate limit exceeded. Will re-execute in 10 seconds.")
      :timer.sleep(10*1000)
      get_summoner_matchlist(account_id, api_key)
    end
  end

  ## gets summoner info such as name, etc. given the account ID
  def get_summoner_info(account_id, api_key) do
    :timer.sleep(400)
    summoner_info=RiotGames.get!("/lol/summoner/v4/summoners/by-account/#{account_id}?api_key=#{api_key}")
    status_code = summoner_info.status_code
    case status_code do
      429 ->
      IO.puts("Rate Limit reached, too many requests. Will re-execute in 10 seconds")
      :timer.sleep(10000)
      get_summoner_info(account_id, api_key)
      200 ->
      summoner_info=summoner_info.body
      end
  end

  ## gets the first 5 game ID lists from the match list
  def get_games_ids(match_list, base, list_of_game_ids) when base < length(match_list) do
      #gets specific match info dependent on base counter
      final_match =Enum.at(match_list, base)
      game_id = final_match["gameId"]
      #appends the empty list with game IDs
      list_of_game_ids = list_of_game_ids ++ [game_id]
      #recurses to next match via counter
      get_games_ids(match_list, base+1, list_of_game_ids)
  end
  def get_games_ids(match_list, base, list_of_game_ids) do
    list_of_game_ids
  end
  ##given list of matches, returns list of all the game_ids
  def get_games_info(match_list, base, matcheslist) when base < length(match_list) do
      #gets specific match info dependent on base counter
      final_match =Enum.at(match_list, base)
      matcheslist = matcheslist ++ [final_match]
      #recurses to next match via counter
      get_games_info(match_list, base+1, matcheslist)
  end
  def get_games_info(match_list, base, matcheslist) do
    ##displays the list of game IDs
    matcheslist
  end
  ## currently takes 1 game, finds all the participants
  def get_game_participant_list(game_id, api_key) do
    :timer.sleep(400)
    participant_list = elem(Enum.at(RiotGames.get!("lol/match/v4/matches/#{game_id}?api_key=#{api_key}").body, 1), 1)
  end

  ## gets all player IDs from said participant list (from 1 game)
  def get_game_participants_account_id(participant_list, base, account_id_list) when base < length(participant_list) do
    ## gets each player info from the recent player list, including player
    participant = Enum.at(participant_list, base)
    ## gets player ID from the player API info
    participant_info = Map.fetch!(participant, "player")
    participant_account_id = Map.fetch!(participant_info, "accountId")
    ## updates account_id_list with player ID
    account_id_list = account_id_list ++ [participant_account_id]
    get_game_participants_account_id(participant_list, base+1, account_id_list)
  end
  def get_game_participants_account_id(participant_list, base, account_id_list) do
    account_id_list
  end
  ## given list of game IDs, finds all the player IDs within the group of players
  def get_all_game_participants_account_ids(list_of_game_ids, api_key, n, full_account_id_list) when n < length(list_of_game_ids) do
    :timer.sleep(400)
    game_id = Enum.at(list_of_game_ids, n)
    participant_list = get_game_participant_list(game_id, api_key)
    game_acc_id_list = get_game_participants_account_id(participant_list, 0, [])
    ## adds the IDs found to the account ID list
    full_account_id_list = Enum.uniq(Enum.concat(full_account_id_list, game_acc_id_list))
    ##loops through to the next game _id
    get_all_game_participants_account_ids(list_of_game_ids, api_key, n+1, full_account_id_list)
  end
  def get_all_game_participants_account_ids(list_of_game_ids, api_key,n, full_account_id_list) do
    full_account_id_list
  end
  ##gets the last 5 matches of each recent player along with their summoner info, and puts them into a list
  def get_matches_of_participants(account_id_list,api_key, base, all_matches) when base < length(account_id_list) do
    account_id = Enum.at(account_id_list, base)
    summoner_info = get_summoner_info(account_id, api_key)
    match_list=get_summoner_matchlist(account_id, api_key)
    gamelist=get_games_info(match_list, 0, [])
    summoner_info_and_games = [summoner_info] ++ [gamelist]
    ## updates the list, where the first entry of the list is the list with syntax info, matches
    all_matches= all_matches ++ [summoner_info_and_games]
    get_matches_of_participants(account_id_list, api_key, base+1, all_matches)
  end

  def get_matches_of_participants(account_id_list, api_key, base, all_matches) do
    IO.inspect(all_matches)
    all_matches
    #all_matches=Enum.at(all_matches, 0)
  end
  ## simple function to check whether the most recent ID has changed
  def did_summoner_find_new(all_matches, api_key, k) when k < length(all_matches) do
    :timer.sleep(1000)
    ## sleep to account for rate limiting
   account_id=elem(Enum.at(Enum.at(Enum.at(all_matches,k),0),0),1)
   name=elem(Enum.at(Enum.at(Enum.at(all_matches,k),0),2),1)
   #gets most recent match
    finished_match= RiotGames.get!("lol/match/v4/matchlists/by-account/#{account_id}?endIndex=1&api_key=#{api_key}").body
    previous_latest_game_id=Map.fetch!(Enum.at(Enum.at(Enum.at(all_matches,k),1),0), "gameId")
    ##  matches game IDs to see if the latest game are different
    latest_game_id =Map.fetch!(Enum.at(elem(Enum.at(finished_match,0),1),0), "gameId")
    if latest_game_id== previous_latest_game_id do
       #do nothing if there isn't an active game
      IO.puts("#{name} did not finish a game in the last few minutes.")
    else
      IO.puts ("The summoner #{name} just finished a game, game ID value: #{latest_game_id}")
    end
   did_summoner_find_new(all_matches, api_key, k+1)
  end


  def did_summoner_find_new(all_matches,api_key, k) do
    IO.putS("The above summoners finished a game within the last 5 minutes.")
  end
  def is_summoner_in_game(all_matches, api_key, k) when k < length(all_matches) do
    ## sleep to account for rate limiting
    :timer.sleep(1000)
    encrypted_sum_id=elem(Enum.at(Enum.at(Enum.at(all_matches,k),0),1),1)
    name=elem(Enum.at(Enum.at(Enum.at(all_matches,k),0),2),1)
    current_match= RiotGames.get!("lol/spectator/v4/active-games/by-summoner/#{encrypted_sum_id}?api_key=#{api_key}")
    current_match_info=current_match.body
    #current_match has the list of game information, if summoner is in game. if not, list is empty.
    case current_match.status_code do
      429 ->
      IO.puts ("Rate limit exceeded, waiting 10 seconds and re running request.")
      :timer.sleep(10000)
      is_summoner_in_game(all_matches, api_key, k)
      403 ->
      IO.puts ("Got Forbidden, waiting 5 seconds and re running request.")
      :timer.sleep(5000)
      is_summoner_in_game(all_matches, api_key, k)
      404 ->
      IO.puts("#{name}: Currently not in a game.")
      is_summoner_in_game(all_matches, api_key, k+1)
      200 ->
      current_game_id=elem(Enum.at(current_match_info,0),1)
      IO.puts ("The summoner #{name} is currently in a game, game ID value: #{current_game_id}")
      is_summoner_in_game(all_matches, api_key, k+1)
    end
  end

  def is_summoner_in_game(all_matches,api_key, k) do
    last_ok = "The above summoners were in a game."
  end
  ## given times (the # of minutes you want to check), with an n counter at 0, checks to see summoners are in a current game
  def repeat_summoner_check(all_matches, api_key, times, n)  when n < times do
    check_count = n+1
    IO.puts("Checking for summoners in game/their recently finished games every minute for #{times} minutes. This is check ##{check_count}.")
    is_summoner_in_game(all_matches, api_key,0)
    IO.puts("Check #{check_count} done.")
    #too many requests to do both at once so i stuck to one at a time, created 2 separate functions for the repetions of each. Could've made the repetion function justa flat repeat with a function as a parameter but decided against it.
    #did_summoner_find_new(all_matches, api_key, 0)
    #because every request takes 1 second, to have this execute every minute, it takes the diff of the number of requests from 60 seocnds
    :timer.sleep(60000-(1000*length(all_matches)))
    repeat_summoner_check(all_matches,api_key,times,n+1)
  end
  def repeat_summoner_check(all_matches, api_key, times,n) do
    ## checks one final time, lets user know the time is up
    IO.puts("#{times} minutes are over. Running one final check.")
    is_summoner_in_game(all_matches,api_key, 0)
    #did_summoner_find_new(all_matches, api_key, 0)
  end
  def repeat_summoner_last_match(all_matches, api_key, times, n)  when n < times do
    check_count = n+1
    IO.puts("Checking for summoners in game/their recently finished games every minute for #{times} minutes. This is check ##{check_count}.")
    did_summoner_find_new(all_matches, api_key, 0)
    IO.puts("Check #{check_count} done.")
    #too many requests to do both at once so i stuck to
    did_summoner_find_new(all_matches, api_key, 0)
    #because every request takes 1 second, to have this execute every minute, it takes the diff of the number of requests from 60 seocnds
    :timer.sleep(60000-(1000*length(all_matches)))
    repeat_summoner_check(all_matches,api_key,times,n+1)
  end
  def repeat_summoner_last_match(all_matches, api_key, times,n) do
    ## checks one final time, lets user know the time is up
    IO.puts("#{times} minutes are over. Running one final check.")
    did_summoner_find_new(all_matches, api_key, 0)
  end
  def find_recently_played_with_matches(name) do
    IO.puts("API keys expire every 24 hours. Please be sure to check and update the daily api_key value in the script.")
    ## checks to make sure name entered has valid string
    if String.match?(name, ~r/^[[:alnum:]]+$/) do
    ## made api a universal variable since prompt asked for only name as a parameter, can alter this
    ## also assumed a universal API key, otherwise, will have to update riot api key as needed
    ## accounted for different test cases, but API key MUST be correct or this script will error out.
        api_key="RGAPI-e5410295-e92e-46ec-b831-b70e7966a686"
        ##gets account ID and info of summoner
        account_ID=get_summoner_accountID(name,api_key)
        summ_info = get_summoner_info(account_ID,api_key)
        IO.puts("Summoner Info:")
        IO.inspect(summ_info)
        ## gets most recent 5 games of summoner (can recode this to not have 5 hard coded)
        IO.puts("Getting recent match info for summoner...")
        match_list=get_summoner_matchlist(account_ID,api_key)
        ## gets list of game IDs for these 5 most recent games
        game_list=get_games_ids(match_list, 0, [])
        IO.puts("Match info received! Getting match player info...")
        :timer.sleep(1000*5)
        ## gets all the unique account IDs of the players in these matches
        account_ids_list = get_all_game_participants_account_ids(game_list, api_key, 0, [])
        IO.puts("Getting recent players' match info")
        ## total_matches is a list that has both summoner info and matches of each player in the summoner's most recent
        total_matches = get_matches_of_participants(account_ids_list,api_key, 0,[])
        IO.puts("All match information found. Waiting 2 minutes due to rate limiting API")
        IO.puts("The below function will now check to see if the recently played with summoners are currently in a game. If you wish to find whether these summoners will have finished a game in the next 5 minutes, please correct this in the code by uncommenting the repeat_summoner_last_match; due to rate limiting, I could not run both requests at the same time.")
        ## sleeps so that the summoner check function won't end up returning an empty list due to rate limiting.
        :timer.sleep(120000)
        ## the below 2 functions will check played-with summoners to see if they're a. in game currently, or b. just finished a game within the last 5 min. I'm only using one function at a time due to rate limiting, feel free to comment one out or the other to test.
        repeat_summoner_check(total_matches,api_key, 5,0)
        ##repeat_summoner_last_match(total_matches,api_key,5,0)
        total_matches
    else
    _name =IO.gets("Please enter a summoner name that does not include special characters: ") |> String.trim
    find_recently_played_with_matches(_name)
  end

end
def test_cases() do
  testcasenumber=IO.gets("Test case #1: Input a non-existent summoner-name 'aaaaaaaaaaaaaaaaaa' \nTest case #2: Input a summoner-name with illegal characters: '%*#$%$' \nMost other test cases having to do with response code and an improper api_key is addressed within the code. Please type the numerical value of the test case you'd like to execute and press enter afterwards: ")|>String.trim
  case testcasenumber do
    "1" ->
      find_recently_played_with_matches("aaaaaaaaaaaaaaaaaa")
    "2" ->
      find_recently_played_with_matches("%*#$%$")
    end
  end
end
