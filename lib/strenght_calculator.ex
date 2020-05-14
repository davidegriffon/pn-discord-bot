defmodule PokemonNoir.StrenghtCalculator do
  alias PokemonNoir.Types

  defp update_relations(existing_relations, types, factor) do
    updates = for type <- types, into: %{} do
      previous_factor = if existing_relations[type] == :nil, do: 1.0, else: existing_relations[type]
      new_factor = previous_factor * factor
      {type, new_factor}
    end
    Map.merge(existing_relations, updates)
  end

  defp add_remaining_relations(relations) do
    remaining_types = Types.types -- Map.keys(relations)
    relations
    |> update_relations(remaining_types, 1.0)
  end

  def generate_relations(relations, type, scope) do
    # note: scope is either "from" or "to"
    case type do
      :nil ->
        relations
      _ when is_bitstring(type) ->
        relations
        |> update_relations(Types.types_relations[type]["no_damage_" <> scope], 0.0)
        |> update_relations(Types.types_relations[type]["double_damage_" <> scope], 2.0)
        |> update_relations(Types.types_relations[type]["half_damage_" <> scope], 0.5)
        |> add_remaining_relations
    end
  end

  defp reshape_relations(relations) do
    relations
    |> Map.to_list
    # note: at this stage there is a list of tuples: [{"water", 1.0}, {"fire", 0.5}, etc...]
    |> Enum.group_by(fn tup -> elem(tup, 1) end, fn tup -> elem(tup, 0) end)
  end

  def calculate_defense(type_one, type_two \\ :nil) do
    %{}
    |> generate_relations(type_one, "from")
    |> generate_relations(type_two, "from")
    |> reshape_relations
  end

  def calculate_attack(type_one) do
    %{}
    |> generate_relations(type_one, "to")
    |> reshape_relations
  end

  def format_type_list(types) do
    ita = for eng <- types, do: Types.ita(eng)
    Enum.join(ita, ", ")
  end

  def format(relations) do
    no_damage      = if relations[0.0],  do: "Nullo: #{format_type_list(relations[0.0])}\n", else: ""
    quarter_damage = if relations[0.25], do: "Un quarto: #{format_type_list(relations[0.25])}\n", else: ""
    half_damage    = if relations[0.5],  do: "Dimezzato: #{format_type_list(relations[0.5])}\n", else: ""
    normal_damage  = if relations[1.0],  do: "Normale: #{format_type_list(relations[1.0])}\n", else: ""
    double_damage  = if relations[2.0],  do: "Doppio: #{format_type_list(relations[2.0])}\n", else: ""
    quad_damage    = if relations[4.0],  do: "Quadruplo: #{format_type_list(relations[4.0])}\n", else: ""
    no_damage <> quarter_damage <> half_damage <> normal_damage <> double_damage <> quad_damage
  end
end