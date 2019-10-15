# BlitzMatchHistory

**Open Command Prompt and cd to wherever the downloaded blitz_match_history folder  is located**

This project's main function in module RiotGames find_recently_played_with(name); this function given a summoner name, finds the 5 most recent matches played by said summoner, as well as those who played with the input summoner and their respective recent 5 matches in those 5 games, outputted in a list that is organized by player (matches organized by most recent to least recent).

Then, the function checks every minute for 5 minutes to see if these players are in a current game and will log a message if there exists a current game. This can be tweaked in the function settings to also check for if these players have finished a game suddenly in the last 5 minutes (also checked by minute).

RiotGames.test_cases allows for the user to examine a few test cases I came up with that would be of concern (a summoner name that doesn't exist, an illegal summoner name, etc.). 

Many of the issues that arose mainly dealt with status codes of the API call; I've dealt with the API call issues I felt were the most relevant (in this case, making sure that the rate limiting didn't throw an error in my code/skip over a player, and to always check to make sure the API key is correct and up to date. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `blitz_match_history` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blitz_match_history, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/blitz_match_history](https://hexdocs.pm/blitz_match_history).

