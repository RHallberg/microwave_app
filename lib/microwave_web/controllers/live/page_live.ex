defmodule MicrowaveWeb.PageLive do
  use MicrowaveWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, pid} = Microwave.MicrowaveTimer.start_link(%{topic: "st4", id: "foo"})
    if connected?(socket) do
      MicrowaveWeb.Endpoint.subscribe("st4")
    end
    {:ok,
      assign(
        socket,
        topic: "st4",
        time: 0,
        microwave: pid
    )}
  end

  @impl true
  def handle_event("increment_time", _params, socket) do
    {:noreply, assign(socket, time: socket.assigns.time + 1)}
  end

  @impl true
  def handle_event("decrement_time", _params, socket = %{assigns: %{time: time}}) do
    new_time = unless time == 0, do: time - 11, else: 0
    {:noreply, assign(socket, time: new_time)}
  end

  @impl true
  def handle_event("submit_time", %{"microwave" => %{"time" => time}}, socket = %{assigns: %{microwave: microwave}}) do
    Microwave.MicrowaveTimer.start_timer(microwave, Integer.parse(time) |> elem(0))
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "microwave_done", payload: id}, socket ) do
    Logger.info("Microwave #{id} done!")
    {:noreply, socket}
  end
end