defmodule MicrowaveWeb.PageLive do
  use MicrowaveWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do

    microwave_id = "foo"
    microwaves = %{microwave_id => %{
      pid: Microwave.MicrowaveTimer.start_link(%{topic: "st4", id: microwave_id}) |> elem(1),
      state: :available
    }}
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
    available = find_available(microwaves)
    start_if_available(socket, Integer.parse(time) |> elem(0), find_available(microwaves))
  end

  @impl true
  def handle_info(%{event: "microwave_done", payload: id}, socket = %{assigns: %{microwaves: microwaves}} ) do
    {:noreply, assign(socket, microwaves: %{microwaves | id => %{microwaves[id] | state: :available} })}
  end

  defp start_if_available(socket, _time, nil) do
    Logger.info("No microwave available!")
    {:noreply, socket}
  end

  defp start_if_available(socket = %{assigns: %{microwaves: microwaves}}, time, id) do
    Microwave.MicrowaveTimer.start_timer(microwaves[id].pid, time)
    {:noreply, assign(socket, microwaves: %{microwaves | id => %{microwaves[id] | state: :busy} })}
  end


  defp find_available(microwaves) do
    available = Enum.find(microwaves, fn m -> m
      |> elem(1)
      |> Map.fetch(:state)
      |> elem(1) == :available end)
    unless is_nil(available), do: (available |> elem(0)), else: available
  end
end