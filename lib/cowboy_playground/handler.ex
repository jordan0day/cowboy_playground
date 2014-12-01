defmodule CowboyPlayground.Handler do
  @servers [%{host: "localhost", port: 4010}, %{host: "localhost", port: 4011}]

  def on_request(req) do
    IO.puts "in on_request! #{inspect req}"
    req
  end

  def init({transport, proto_name}, req, opts) do
    IO.puts "initting httphandler!"
    IO.puts "\ntransport: #{inspect transport}\n"
    IO.puts "\nproto_name: #{inspect proto_name}\n"

    # Seed the RNG, since the httphandler is re-initted for each request, we 
    # need to re-seed on init -- otherwise :random.uniform will always return
    # the same result.
    :random.seed(:erlang.now())

    {:ok, req, nil}
  end

  def handle(req, state) do
    IO.puts "in handle..."
    IO.puts "Original request:\n#{inspect req}\n"
    
    {bindings, req} = :cowboy_req.bindings(req)
    IO.puts "bindings:#{inspect bindings}"

    {cookies, req} = :cowboy_req.cookies(req)
    IO.puts "cookies:#{inspect cookies}"

    {headers, req} = :cowboy_req.headers(req)
    IO.puts "headers:#{inspect headers}"

    #{metadata, req} = :cowboy_req.meta(req)
    #IO.puts "metadata:#{inspect metadata}"

    {peer, req} = :cowboy_req.peer(req)
    IO.puts "peer:#{inspect peer}"

    {querystring, req} = :cowboy_req.qs(req)
    IO.puts "querystring:#{inspect querystring}"

    {version, req} = :cowboy_req.version(req)
    IO.puts "version:#{inspect version}"

    {host, req} = :cowboy_req.host(req)
    IO.puts "\nhost: #{inspect host}"
    {hostinfo, req} = :cowboy_req.host_info(req)
    IO.puts "\nhostinfo: #{inspect hostinfo}"
    {host_url, req} = :cowboy_req.host_url(req)
    IO.puts "\nhost_Url: #{inspect host_url}"
    {port, req} = :cowboy_req.port(req)
    IO.puts "\nport: #{inspect port}"
    {path, req} = :cowboy_req.path(req)
    IO.puts "\npath: #{inspect path}"
    {url, req} = :cowboy_req.url(req)
    IO.puts "\nurl: #{inspect url}"

    {method, req} = :cowboy_req.method(req)
    IO.puts "\nmethod: #{inspect method}"

    server = get_random_server
    IO.puts "\nforwarding request to #{server.host}, port #{server.port}"

    new_url = Regex.replace(~r/^#{host_url}/, url, "http://#{server.host}:#{server.port}")

    IO.puts "\nnew_url: #{new_url}"

    options = Application.get_env(:cowboy_playground, :httpoison_config, [])

    IO.puts "options: #{inspect options}"

    case method do
      "GET" ->
        try do
          {result, response} = HTTPoison.get(new_url)
          IO.puts "result: #{inspect result}"
          IO.puts "response: #{inspect response}"
          response_headers = response.headers
                              |> Map.keys
                              |> Enum.map(fn key ->
                                {key, response.headers[key]}
                              end)
          {:ok, req} = :cowboy_req.reply(response.status_code, response_headers, response.body, req)
        rescue
          e ->
            IO.puts "ERROR! : #{inspect e}"
        end

    end

    {:ok, req, state}
  end

  def terminate(reason, req, state) do
    IO.puts "in terminate..."
    IO.puts "\nreason: #{inspect reason}\n"
  end

  defp get_random_server do
    index = :random.uniform(length(@servers)) - 1
    Enum.at(@servers, index)
  end
end