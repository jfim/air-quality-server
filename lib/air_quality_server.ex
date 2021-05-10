defmodule AirQualityServer do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    # Accept connection and spawn child task to handle it
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(AirQualityServer.TaskSupervisor, fn -> serve(client) end)

    :ok = :gen_tcp.controlling_process(client, pid)

    # Log connection
    {:ok, {ip_addr, port}} = :inet.peername(client)

    peer =
      if tuple_size(ip_addr) == 4 do
        ip_addr
        |> Tuple.to_list()
        |> Enum.join(".")
      else
        ip_addr
        |> Tuple.to_list()
        |> Enum.map(fn x -> Integer.to_string(x, 16) end)
        |> Enum.join(":")
      end

    Logger.info("Accepted connection from #{peer}:#{port}")

    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> handle_line()

    ack_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp ack_line(socket) do
    :gen_tcp.send(socket, "ok\n")
  end

  defp handle_line(line) do
    # Prepend current time to the log entry received, then send it to the AirQualityDataStore
    {:ok, timestamp} = Timex.local() |> Timex.format("{ISO:Extended}")
    full_line = "#{timestamp},#{line}"

    members = :pg2.get_members(:air_quality_line_notifications)

    case members do
      [pids | rest] ->
        Enum.each(members, fn pid -> GenServer.cast(pid, {:air_quality_log_line, full_line}) end)

      # Ignored
      [] ->
        ""

      # Ignored
      {:error, _} ->
        ""
    end

    #    AirQualityDataStore.store_line(full_line)
  end
end
