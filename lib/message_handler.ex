defmodule PokemonNoir.MessageHandler do
  alias Nostrum.Api
  alias PokemonNoir.StrenghtCalculator

  @pokemon_api_base_url "https://pokeapi.co/api/v2/pokemon"

  @roll_pattern ~r/^:r[[:blank:]]*(?<sign>[[\-\+]]{0,1})?[[:blank:]]*(?<mod>[[:digit:]])*$/
  @info_pattern ~r/^:i[[:blank:]]+(?<pokemon>[[:alnum:]]*)$/
  @type_pattern ~r/^:t[[:blank:]]+(?<type>[[:alnum:]]*)$/
  @dice_test_pattern ~r/^:dicetest$/
  @message_types [
    {@roll_pattern, :roll},
    {@info_pattern, :info},
    {@type_pattern, :type},
    {@dice_test_pattern, :test},
    {~r/^:griffo$/, :griffo},
    {~r/^:fanculo$/, :fuck},
  ]

  defp parse(msg) do
    {_, type} = Enum.find(@message_types, {nil, :unknown}, fn {reg, type} -> 
       String.match?(msg, reg)
     end)
    {type, msg}
  end

  defp do_reply({:roll, msg}, channel_id, author) do
    %{"sign" => sign, "mod" => mod} = Regex.named_captures(@roll_pattern, msg)
    sign = if sign == "", do: "+", else: sign
    absolute_mod = if mod == "", do: 0, else: String.to_integer(mod)
    signed_mod = if sign == "-", do: absolute_mod * -1, else: absolute_mod
    first_roll = Enum.random(1..6)
    second_roll = Enum.random(1..6)
    dice_sum = first_roll + second_roll + signed_mod
    mod_str = if signed_mod == 0, do: "", else: " #{sign} #{mod}"
    Api.create_message(channel_id, "#{author.username}: [#{first_roll}] + [#{second_roll}]#{mod_str} = #{dice_sum}")
  end

  defp do_reply({:info, msg}, channel_id, author) do
    %{"pokemon" => pokemon} = Regex.named_captures(@info_pattern, msg)
    url = "#{@pokemon_api_base_url}/#{pokemon}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"types" => types, "sprites" => %{"front_default" => image}} = body |> Poison.decode!
        str_types = for t <- types, do: t["type"]["name"]
        defense = apply(StrenghtCalculator, :calculate_defense, str_types)

        Api.create_message(channel_id, "Pokemon #{pokemon} trovato!")
        Api.create_message(channel_id, "Tipo: #{StrenghtCalculator.format_type_list(str_types)}")
        Api.create_message(channel_id, "Difesa 🛡\n#{StrenghtCalculator.format(defense)}")
        Api.create_message(channel_id, "\nhttps://wiki.pokemoncentral.it/#{pokemon}")

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Api.create_message(channel_id, "Pokemon #{pokemon} non trovato :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        :ignore
    end
  end

  defp do_reply({:type, msg}, channel_id, author) do
    %{"type" => type} = Regex.named_captures(@type_pattern, msg)
    attack = StrenghtCalculator.calculate_attack(type)
    defense = StrenghtCalculator.calculate_defense(type)
    message = """
    Tipo #{StrenghtCalculator.format_type_list([type])}

    Attacco ⚔️
    #{StrenghtCalculator.format(attack)}
    Difesa 🛡
    #{StrenghtCalculator.format(defense)}
    """
    Api.create_message(channel_id, message)
  end

  defp do_reply({:griffo, msg}, channel_id, author) do
    Api.create_message(channel_id, "Best scoprirovine evah!1!!111!")
  end

  defp do_reply({:fuck, msg}, channel_id, author) do
    Api.create_message(channel_id, "SI MA STAI CALMO")
  end

  defp do_reply({:test, msg}, channel_id, _author) do
    dice = for i <- 0..600, do: Enum.random(1..6)
    text = """
    1: #{Enum.reduce(dice, 0, fn i, acc -> if i == 1, do: acc + 1, else: acc end)}
    2: #{Enum.reduce(dice, 0, fn i, acc -> if i == 2, do: acc + 1, else: acc end)}
    3: #{Enum.reduce(dice, 0, fn i, acc -> if i == 3, do: acc + 1, else: acc end)}
    4: #{Enum.reduce(dice, 0, fn i, acc -> if i == 4, do: acc + 1, else: acc end)}
    5: #{Enum.reduce(dice, 0, fn i, acc -> if i == 5, do: acc + 1, else: acc end)}
    6: #{Enum.reduce(dice, 0, fn i, acc -> if i == 6, do: acc + 1, else: acc end)}
    """
    Api.create_message(channel_id, "dadi: #{Enum.join(dice, ", ")}")
    Api.create_message(channel_id, text)
  end

  defp do_reply({_, msg}, _channel_id, _author) do
    :ignore
  end

  def handle(msg) do
    %{:channel_id => cid, :author => author} = msg
    IO.puts("author: #{inspect author.username}")
    msg.content
    |> parse
    |> do_reply(cid, author)
  end
end