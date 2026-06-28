defmodule Sabotage do
  def generate_sabotage() do
    [:steal, :lock, :revert] |> Enum.random()
  end

  def handle_sabotage(:lock, target_pid) do
    send(target_pid, {:sabotage, :lock})
  end
end
