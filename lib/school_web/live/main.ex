defmodule SchoolWeb.MainLive do
  use SchoolWeb, :live_view

  alias School.Logic
  alias School.State

  import SchoolWeb.GameComponents

  @lock_timeout 5_000
  @meme_timeout 2_000

  @impl true
  def mount(_params, _session, socket) do
    package = Logic.generate_package()

    Phoenix.PubSub.subscribe(School.PubSub, "game_room")

    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:local_player, nil)
      |> assign(:package, package)
      |> assign(:timestamp, nil)
      |> assign(:validation_result, :correct)
      |> assign(:game_state, :waiting)
      |> assign(:active_rules, active_rules)
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:available_sabotages, %{steal: 0, lock: 0, revert: 0})
      |> assign(:selected_sabotage, nil)
      |> assign(:sabotage_descriptions, Logic.descriptions_by_sabotages())
      |> assign(:sabotage_target, nil)
      |> assign(:score, 0)
      |> assign(:is_locked?, false)
      |> assign(:is_flipped?, false)
      |> assign(:show_meme?, false)
      |> assign(:meme_id, 0)
      |> assign(:player_list, [])

    # Process.send_after(self(), :hide_meme, @meme_timeout)
    {:ok, new_socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    local_player = State.add_player(name, self())

    new_socket =
      socket
      |> assign(:local_player, local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("ready", _params, socket) do
    local_player = socket.assigns.local_player
    {updated_local_player, _game_state} = State.player_ready(local_player.name)

    new_socket =
      socket
      |> assign(:local_player, updated_local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("toggle_sabotage_menu", %{"victim" => pid}, socket) do
    new_target = if socket.assigns.sabotage_target == pid, do: nil, else: pid
    {:noreply, assign(socket, :sabotage_target, new_target)}
  end

  @impl true
  def handle_event(
        "choose_sabotage",
        %{"victim" => victim_str, "sabotage" => sabotage_str},
        socket
      ) do
    sabotage = String.to_existing_atom(sabotage_str)
    target_pid = victim_str |> String.to_charlist() |> :erlang.list_to_pid()
    new_sabotages = State.use_sabotage(target_pid, sabotage)

    new_socket =
      socket
      |> assign(:available_sabotages, new_sabotages)
      |> assign(:sabotage_target, nil)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("decline", _params, socket) do
    new_socket = validation("swipe-left", :invalid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    new_socket = validation("swipe-right", :valid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:next_package, socket) do
    package = Logic.generate_package()

    new_socket =
      socket
      |> assign(:package, package)
      |> assign(:is_flipped?, false)
      |> push_event("reset-package-card", %{})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_start, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_ended, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:tick_update, current_game_time}, socket) do
    width = build_game_time_loading_bar(current_game_time)

    new_socket =
      socket
      |> push_event("timer-tick", %{time: current_game_time, width: width})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:update_rules, socket) do
    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:active_rules, active_rules)

    {:noreply, new_socket}
  end

  def handle_info({:update_player_list, updated_player_list}, socket) do
    new_socket =
      socket
      |> assign(:player_list, updated_player_list)

    {:noreply, new_socket}
  end

  def handle_info({:sabotage, :steal}, socket) do
    {:noreply, show_meme(socket)}
  end

  def handle_info({:sabotage, :revert}, socket) do
    new_socket =
      socket
      |> assign(:is_flipped?, true)
      |> show_meme()

    {:noreply, new_socket}
  end

  def handle_info({:sabotage, :lock}, socket) do
    new_socket =
      socket
      |> assign(:is_locked?, true)
      |> show_meme()

    Process.send_after(self(), :unlock, @lock_timeout)
    {:noreply, new_socket}
  end

  def handle_info(:unlock, socket) do
    new_socket =
      socket |> assign(:is_locked?, false)

    {:noreply, new_socket}
  end

  def handle_info(:hide_meme, socket) do
    new_socket =
      socket |> assign(:show_meme?, false)

    {:noreply, new_socket}
  end

  defp show_meme(socket) do
    Process.send_after(self(), :hide_meme, @meme_timeout)

    socket
    |> assign(:show_meme?, true)
    |> assign(:meme_id, socket.assigns.meme_id + 1)
  end

  defp validation(swipe_direction, expected, socket) do
    package = socket.assigns.package

    {updated_player, decision, validation_msg, sabotages} =
      State.update_player_score(self(), package, expected)

    new_socket =
      socket
      |> assign(:validation_result, decision)
      |> assign(:validation_msg, validation_msg)
      |> assign(:local_player, updated_player)
      |> assign(:available_sabotages, sabotages)
      |> assign(:score, updated_player.score)
      |> push_event(swipe_direction, %{})

    Process.send_after(self(), :next_package, 1_000)

    new_socket
  end

  def build_game_time_loading_bar(game_time) do
    max_game_time = State.max_game_time()
    game_time / max_game_time * 100
  end
end
