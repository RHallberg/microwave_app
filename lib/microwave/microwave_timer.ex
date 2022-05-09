defmodule Microwave.MicrowaveTimer do
  use GenServer
  require Logger

  @interval 1000

  def start_link(args = %{topic: topic, id: id}, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def start_timer(pid, time) do
    GenServer.cast(pid, {:start_timer, time})
  end

  def init(args = %{topic: topic, id: id}) do
    st = %{
      topic: topic,
      id: id,
      current: 0,
      timer: nil
    }

    {:ok, st}
  end

  def handle_call(:get, _from, st) do
    {:reply, st.current, st}
  end

  def handle_cast({:start_timer, time}, st) do
    {:noreply, %{st | current: time - 1, timer: :erlang.start_timer(@interval, self(), :tick)}}
  end

  def handle_info({:timeout, _timer_ref, :tick}, st) when st.current > 0 do
    new_timer = :erlang.start_timer(@interval, self(), :tick)
    :erlang.cancel_timer(st.timer)
    MicrowaveWeb.Endpoint.broadcast(st.topic, "microwave_tick", %{id: st.id, current: st.current})

    {:noreply, %{st | current: st.current - 1, timer: new_timer}}
  end

  def handle_info({:timeout, _timer_ref, :tick}, st) when st.current <= 0 do
    :erlang.cancel_timer(st.timer)
    MicrowaveWeb.Endpoint.broadcast(st.topic, "microwave_done", st.id)
    {:noreply, %{st | current: 0, timer: nil}}
  end

end