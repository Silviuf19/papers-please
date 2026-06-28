defmodule Sabotage do
  def generate_sabotage() do
    [:steal, :lock, :revert] |> Enum.random()
  end
end
