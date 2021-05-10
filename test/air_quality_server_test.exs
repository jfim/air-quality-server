defmodule AirQualityServerTest do
  use ExUnit.Case
  doctest AirQualityServer

  test "greets the world" do
    assert AirQualityServer.hello() == :world
  end
end
