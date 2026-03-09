# AirQualityServer

Elixir OTP application that receives air quality sensor data over TCP and logs it to daily CSV files.

Sensors connect via TCP and send comma-separated readings (one per line). This matches with the sensor data sent by [this air quality sensor](https://github.com/jfim/air-quality-monitor-firmware).

The server prepends an ISO timestamp, broadcasts the data via a `:pg` group, and logs it to daily CSV files (`YYYY-MM-DD.csv`). The `:pg` group allows other processes to subscribe and act on the data in real time. The cluster can be joined using libcluster.

The CSV flush rate is configurable to limit wear on devices with low endurance (eg. SD card) and limit noise on noisy write devices (eg. mechanical hard drives).

## Running Locally

```bash
mix deps.get
mix run --no-halt
```

## Running with Docker

```bash
cp .env.example .env
# Edit .env as needed
docker-compose up
```

CSV logs are persisted to a Docker volume mounted at `/data`. To use a host directory instead, update `docker-compose.yml`:

```yaml
volumes:
  - /path/on/host:/data
```

## Environment Variables

See `.env.example` for a full template.

| Variable | Description | Default |
|---|---|---|
| `SERVER_PORT` | TCP listen port | `1234` |
| `LOG_DIR` | Directory for CSV log files | `.` (local), `/data` (Docker) |
| `LOG_BUFFER_SIZE_BYTES` | Write buffer size in bytes | `1048576` (1 MB) |
| `LOG_FLUSH_INTERVAL_SECONDS` | Flush interval in seconds | `900` (15 min) |
| `HOSTNAME` | Erlang node name | `air_quality_server` |
| `NAMESPACE` | Clustering namespace | `air_quality` |
| `ERLANG_DIST_PORT` | Erlang distribution port | `9000` |
| `ERLANG_COOKIE` | Clustering cookie | `change_this_in_production` |

## CSV Format

Each daily file has 23 columns:

```
logTs,macAddress,millis,co2Status,co2Ppm,particleChecksumOk,
particlePm1_0,particlePm2_5,particlePm10_0,particleCount0_3um,
particleCount0_5um,particleCount1_0um,particleCount2_5um,
particleCount5_0um,particleCount10_0um,temp,humidity,
tempChecksumOk,humidityChecksumOk,co2eqPpm,tvocPpb,
co2eqChecksumOk,tvocChecksumOk
```
