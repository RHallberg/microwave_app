defmodule MicrowaveWeb.PageLive do
  use MicrowaveWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do

    ids = ["one", "two", "three", "four", "five", "six"]

    microwaves = Enum.map(ids, fn id -> %{
      id: id,
      pid: Microwave.MicrowaveTimer.start_link(%{topic: "st4", id: id}) |> elem(1),
      state: :available,
      time: 0
      } end)

    if connected?(socket) do
      MicrowaveWeb.Endpoint.subscribe("st4")
    end
    {:ok,
      assign(
        socket,
        topic: "st4",
        time: 0,
        microwaves: microwaves
    )}
  end

  @impl true
  def handle_event("increment_time", _params, socket) do
    {:noreply, assign(socket, time: socket.assigns.time + 1)}
  end

  @impl true
  def handle_event("decrement_time", _params, socket = %{assigns: %{time: time}}) do
    new_time = unless time == 0, do: time - 1, else: 0
    {:noreply, assign(socket, time: new_time)}
  end

  @impl true
  def handle_event("submit_time", %{"microwave" => %{"time" => time}}, socket = %{assigns: %{microwaves: microwaves}}) do
    available = Enum.find(microwaves, fn m -> m.state == :available end)
    start_if_available(socket, Integer.parse(time) |> elem(0), available)
  end

  @impl true
  def handle_info(%{event: "microwave_tick", payload: %{id: id, current: current}}, socket = %{assigns: %{microwaves: microwaves}} ) do
    {microwave, i} = Enum.with_index(microwaves) |> Enum.find(fn {m, _i} -> m.id == id  end)
    {:noreply, assign(socket, microwaves: List.replace_at(microwaves, i, %{microwave | time: current}))}
  end

  @impl true
  def handle_info(%{event: "microwave_done", payload: id}, socket = %{assigns: %{microwaves: microwaves}} ) do
    {microwave, i} = Enum.with_index(microwaves) |> Enum.find(fn {m, _i} -> m.id == id  end)
    {:noreply, assign(socket, microwaves: List.replace_at(microwaves, i, %{microwave | state: :available, time: 0}))}
  end

  defp start_if_available(socket, _time, nil) do
    Logger.info("No microwave available!")
    {:noreply, socket}
  end

  defp start_if_available(socket = %{assigns: %{microwaves: microwaves}}, time, available) do
    Microwave.MicrowaveTimer.start_timer(available.pid, time)
    {microwave, i} = Enum.with_index(microwaves) |> Enum.find(fn {m, _i} -> m.id == available.id  end)
    {:noreply, assign(socket, microwaves: List.replace_at(microwaves, i, %{microwave | state: :busy, time: time}))}
  end

end