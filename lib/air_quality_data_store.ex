defmodule AirQualityDataStore do
  use GenServer

  def store_line(line) do
    GenServer.cast(AirQualityDataStore.Worker, {:air_quality_log_line, line})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    log_dir = System.get_env("LOG_DIR", ".")
    buffer_size = get_env_int("LOG_BUFFER_SIZE_BYTES", 1024 * 1024)
    flush_interval = get_env_int("LOG_FLUSH_INTERVAL_SECONDS", 15 * 60) * 1000
    File.mkdir_p!(log_dir)

    log_opts = {log_dir, buffer_size, flush_interval}
    curr_date = Timex.today()
    curr_file = open_log_file(log_opts, "#{curr_date}.csv")

    # Register for notifications
    :pg.join(:air_quality_line_notifications, self())

    {:ok, {curr_file, curr_date, log_opts}}
  end

  def handle_cast({:air_quality_log_line, line}, {curr_file, file_date, log_opts}) do
    curr_date = Timex.today()

    # Close the current file and open a new one if the date has changed
    curr_file =
      if curr_date != file_date do
        File.close(curr_file)
        open_log_file(log_opts, "#{curr_date}.csv")
      else
        curr_file
      end

    IO.write(curr_file, line)

    {:noreply, {curr_file, curr_date, log_opts}}
  end

  defp open_log_file({log_dir, buffer_size, flush_interval}, file_name) do
    file_path = Path.join(log_dir, file_name)
    file_exists = File.exists?(file_path)

    {:ok, curr_file} =
      File.open(file_path, [:append, {:delayed_write, buffer_size, flush_interval}])

    # Write header if the file was just created
    if !file_exists do
      IO.write(
        curr_file,
        "logTs,macAddress,millis,co2Status,co2Ppm,particleChecksumOk,particlePm1_0,particlePm2_5,particlePm10_0,particleCount0_3um,particleCount0_5um,particleCount1_0um,particleCount2_5um,particleCount5_0um,particleCount10_0um,temp,humidity,tempChecksumOk,humidityChecksumOk,co2eqPpm,tvocPpb,co2eqChecksumOk,tvocChecksumOk\n"
      )
    end

    curr_file
  end

  defp get_env_int(name, default) do
    case System.get_env(name) do
      nil -> default
      val -> String.to_integer(val)
    end
  end
end
