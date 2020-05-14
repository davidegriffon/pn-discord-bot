defmodule PokemonNoirTypeTest do
  use ExUnit.Case
  
  import PokemonNoir.StrenghtCalculator, only: [calculate_defense: 1, calculate_defense: 2]

  test "Test defense of one type" do
    assert calculate_defense("water") == %{
      2.0 => Enum.sort(["grass", "electric"]),
      1.0 => Enum.sort(["normal", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "fairy"]),
      0.5 => Enum.sort(["fire", "steel", "water", "ice"])
    }
  end

  test "Test defense souble type" do
    assert calculate_defense("electric", "flying") == %{
      2.0 => Enum.sort(["ice", "rock"]),
      1.0 => Enum.sort(["normal", "fire", "water", "electric", "poison", "psychic", "ghost", "dragon", "dark", "fairy"]),
      0.5 => Enum.sort(["steel", "bug", "grass", "fighting", "flying"]),
      0.0 => Enum.sort(["ground"]),
    }
  end
end
