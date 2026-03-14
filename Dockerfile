# Dockerfile
FROM elixir:1.17.3-otp-27

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy the mix.exs and mix.lock files first to leverage Docker cache
COPY mix.exs mix.lock ./
COPY config config

# Install hex package manager and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy the rest of the application
COPY . .

# Compile the application
RUN mix compile

# Create a new entrypoint script that enables Erlang distribution
RUN echo '#!/bin/sh\n\
exec elixir \
    --name air_quality_server@${HOSTNAME}.${NAMESPACE} \
    --cookie ${ERLANG_COOKIE} \
    --erl "-kernel inet_dist_listen_min 9000" \
    --erl "-kernel inet_dist_listen_max 9000" \
    -S mix run --no-halt' > /app/docker-entrypoint.sh && \
    chmod +x /app/docker-entrypoint.sh

# Create default log directory
RUN mkdir -p /data
ENV LOG_DIR=/data

# Expose the TCP port and Erlang distribution port
EXPOSE 1234 9000

# Set the entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
