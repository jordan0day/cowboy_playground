defmodule CowboyPlayground.Handler do
  def on_request(req) do
    IO.puts "in on_request! #{inspect req}"
    req
  end

  def init({transport, proto_name}, req, opts) do
    IO.puts "initting httphandler!"
    IO.puts "\ntransport: #{inspect transport}\n"
    IO.puts "\nproto_name: #{inspect proto_name}\n"
    #IO.puts "\nreq: #{inspect req}\n"
    #IO.puts "\nopts: #{inspect opts}\n"

    {:ok, req, nil}
  end

  def handle(req, state) do
    IO.puts "in handle..."
    #IO.puts "\nreq: #{inspect req}\n"
    #IO.puts "\nstate: #{inspect state}\n"
    {host, req} = :cowboy_req.host(req)
    IO.puts "\nhost: #{inspect host}"
    {hostinfo, req} = :cowboy_req.host_info(req)
    IO.puts "\nhostinfo: #{inspect hostinfo}"
    {host_url, req} = :cowboy_req.host_url(req)
    IO.puts "\nhost_Url: #{inspect host_url}"
    {port, req} = :cowboy_req.port(req)
    IO.puts "\nport: #{inspect port}"
    {:ok, req, state}
  end

  def terminate(reason, req, state) do
    IO.puts "in terminate..."
    IO.puts "\nreason: #{inspect reason}\n"
    #IO.puts "\nreq: #{inspect req}\n"
    #IO.puts "\nstate: #{inspect state}\n"
  end
end