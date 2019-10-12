defmodule RiotGames do
  use HTTPoison.Base

  @expected_fields ~w(
   id accountId puuId name profileIconId revisionDate summonerLevel matches
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
end
