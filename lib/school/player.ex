defmodule School.Player do
  @type t :: %__MODULE__{
          name: String.t(),
          score: integer(),
          pid: pid(),
          ready?: boolean()
        }

  defstruct name: nil,
            score: 0,
            pid: nil,
            ready?: false,
            sabotages: %{steal: 0, lock: 0, revert: 0},
            strike: 0
end
