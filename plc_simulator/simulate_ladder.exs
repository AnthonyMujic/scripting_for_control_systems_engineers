defmodule Commands do
  def branch(branch1, branch2), do: branch1 || branch2
  def xic(bit), do: bit
  def xio(bit), do: not bit
  def xio(piped, bit), do: piped && not bit

  defmacro ote(input, output) do
    {output_name, _, _} = output

    {:=, [], [{output_name, [], nil}, input]}
  end
end

defmodule Logic do
  import Commands

  def execute(params) do
    {xml, _} = :xmerl_scan.file("simple_logic_Routine_RLL.L5X")

    logic =
      :xmerl_xpath.string(
        ~c"/RSLogix5000Content/Controller/Programs/Program/Routines/Routine/RLLContent/Rung/Text/text()",
        xml
      )
      |> Enum.map(fn x ->
        {_, _, _, _, rung, _} = x

        to_string(rung)
        |> String.downcase()
        |> String.split("\n")
        |> List.to_string()
        |> String.replace(");", ") \n")
        |> String.replace(~r/[)][^ ]/, fn x ->
          ") |> " <> String.slice(x, 1..2)
        end)
        |> String.replace("[", "branch(")
        |> String.replace("]", ") |> ")
      end)
      |> List.to_string()
      |> IO.inspect()

    {_, bindings} =
      Code.eval_string(
        logic,
        params,
        __ENV__
      )

    bindings
  end
end

Mix.install([
  {:phoenix_playground, "~> 0.1.6"}
])

defmodule DemoLive do
  use Phoenix.LiveView
  import Logic

  def mount(_params, _session, socket) do
    logic =
      Logic.execute(
        start_pump: false,
        pump_running: false,
        stop_pump: false,
        pump_running_indicator: false
      )

    {:ok, assign(socket, logic: logic)}
  end

  def render(assigns) do
    ~H"""
    <h1> Ladder Logic Simulator </h1>
    <strong class="start_pump" phx-click="start">-|start_pump|-----</strong>
    <strong class="stop_pump" phx-click="stop">-|!stop_pump|-</strong>
    <strong class="pump_running" phx-click="running">-(pump_running)-</strong>
    <br>
    <strong class="pump_running" phx-click="running">-|pump_running|-</strong>
    <br>
    <br>
    <strong class="pump_running" phx-click="running">-|pump_running|-</strong>
    <strong class="pump_running_indicator" phx-click="running_indicator">-(pump_running_indicator)-</strong>

    <style type="text/css">
    body { padding: 4em; }
      .start_pump { background-color: <%= if @logic[:start_pump], do: "lime", else: "white" %>;}
      .stop_pump { background-color: <%= if not @logic[:stop_pump], do: "lime", else: "white" %>;}
      .pump_running { background-color: <%= if @logic[:pump_running], do: "lime", else: "white" %>;}
      .pump_running_indicator { background-color: <%= if @logic[:pump_running_indicator], do: "lime", else: "white" %>;}
    </style>
    """
  end

  def handle_event("start", _params, socket) do
    bindings =
      Keyword.put(socket.assigns.logic, :start_pump, not socket.assigns.logic[:start_pump])

    logic = Logic.execute(bindings)
    {:noreply, assign(socket, logic: logic)}
  end

  def handle_event("stop", _params, socket) do
    bindings = Keyword.put(socket.assigns.logic, :stop_pump, not socket.assigns.logic[:stop_pump])
    logic = Logic.execute(bindings)
    {:noreply, assign(socket, logic: logic)}
  end

  def handle_event("running", _params, socket) do
    bindings =
      Keyword.put(socket.assigns.logic, :pump_running, not socket.assigns.logic[:pump_running])

    logic = Logic.execute(bindings)
    {:noreply, assign(socket, logic: logic)}
  end

  def handle_event("running_indicator", _params, socket) do
    bindings =
      Keyword.put(
        socket.assigns.logic,
        :pump_running_indicator,
        not socket.assigns.logic[:pump_running_indicator]
      )

    logic = Logic.execute(bindings)
    {:noreply, assign(socket, logic: logic)}
  end
end

PhoenixPlayground.start(live: DemoLive, port: 4001)
