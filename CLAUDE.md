# Air Quality Server

Elixir OTP application that receives air quality sensor data over TCP and logs it to daily CSV files.

## Architecture

- **AirQualityServer** (`lib/air_quality_server.ex`) — TCP server on port 1234. Accepts connections, reads line-delimited sensor data, prepends ISO timestamps, broadcasts via `:pg` group, and sends "ok\n" ack.
- **AirQualityDataStore** (`lib/air_quality_data_store.ex`) — GenServer subscribed to `:pg` group. Writes timestamped lines to daily CSV files (`YYYY-MM-DD.csv`) with 1MB write buffer and 15-min flush. Auto-rolls at midnight.
- **Application** (`lib/air_quality_server/application.ex`) — OTP supervisor. Starts `:pg`, libcluster (Gossip strategy), AirQualityDataStore, Task.Supervisor, and the TCP accept loop.

## Data Flow

Sensor → TCP → AirQualityServer (timestamp + broadcast via :pg) → AirQualityDataStore → CSV file

## CSV Format (23 columns)

`logTs,macAddress,millis,co2Status,co2Ppm,particleChecksumOk,particlePm1_0,particlePm2_5,particlePm10_0,particleCount0_3um,particleCount0_5um,particleCount1_0um,particleCount2_5um,particleCount5_0um,particleCount10_0um,temp,humidity,tempChecksumOk,humidityChecksumOk,co2eqPpm,tvocPpb,co2eqChecksumOk,tvocChecksumOk`

## Build & Run

```bash
mix deps.get
mix run --no-halt
```

Or with Docker: `docker-compose up`

## Environment Variables

- `LOG_DIR` — Directory for CSV log files (default: ".", set to "/data" in Docker)
- `LOG_BUFFER_SIZE_BYTES` — Write buffer size in bytes (default: 1048576 / 1MB)
- `LOG_FLUSH_INTERVAL_SECONDS` — Flush interval in seconds (default: 900 / 15 min)
- `PORT` / `SERVER_PORT` — TCP listen port (default: 1234)
- `HOSTNAME` — Erlang node name (default: "air_quality_server")
- `NAMESPACE` — Clustering namespace (default: "air_quality")
- `ERLANG_DIST_PORT` — Distribution port (default: 9000)
- `ERLANG_COOKIE` — Clustering cookie

## Dependencies

- **timex** ~> 3.5.0 — ISO timestamp formatting
- **libcluster** ~> 3.2.2 — Automatic Erlang node clustering

## Tests

```bash
mix test
```

Note: Tests are currently minimal placeholders.

## Conventions

- Elixir ~> 1.17.3, OTP 25
- Code formatting: `mix format`
- Sensor data arrives as comma-separated values over TCP, one reading per line
- The `:pg` pub/sub group (`:air_quality_line_notifications`) allows adding new consumers beyond CSV logging
