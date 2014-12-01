require Logger

defmodule CowboyPlayground.Handler do
  @servers [%{host: "localhost", port: 4010}, %{host: "localhost", port: 4011}]

  def on_request(req) do
    Logger.debug "================================================"
    Logger.debug "================ in on_request! ================"
    Logger.debug "#{inspect req}"
    req
  end

  def init({transport, proto_name}, req, opts) do
    started = :erlang.now()
    Logger.debug "================ initting httphandler! ================"
    Logger.debug "transport: #{inspect transport}"
    Logger.debug "proto_name: #{inspect proto_name}"

    # Seed the RNG, since the httphandler is re-initted for each request, we 
    # need to re-seed on init -- otherwise :random.uniform will always return
    # the same result.
    :random.seed(:erlang.now())

    {:ok, req, started}
  end

  def handle(req, state) do
    Logger.debug "================ in handle... ================"
    # Logger.debug "Original request:#{inspect req}"
    
    {bindings, req} = :cowboy_req.bindings(req)
    # Logger.debug "bindings:#{inspect bindings}"

    {cookies, req} = :cowboy_req.cookies(req)
    Logger.debug "cookies:#{inspect cookies}"

    {headers, req} = :cowboy_req.headers(req)
    Logger.debug "headers:#{inspect headers}"

    #{metadata, req} = :cowboy_req.meta(req)
    #Logger.debug "metadata:#{inspect metadata}"

    {peer, req} = :cowboy_req.peer(req)
    Logger.debug "peer:#{inspect peer}"

    {querystring, req} = :cowboy_req.qs(req)
    Logger.debug "querystring:#{inspect querystring}"

    {version, req} = :cowboy_req.version(req)
    Logger.debug "version:#{inspect version}"

    {host, req} = :cowboy_req.host(req)
    Logger.debug "host: #{inspect host}"
    {hostinfo, req} = :cowboy_req.host_info(req)
    Logger.debug "hostinfo: #{inspect hostinfo}"
    {host_url, req} = :cowboy_req.host_url(req)
    Logger.debug "host_Url: #{inspect host_url}"
    {port, req} = :cowboy_req.port(req)
    Logger.debug "port: #{inspect port}"
    {path, req} = :cowboy_req.path(req)
    Logger.debug "path: #{inspect path}"
    {url, req} = :cowboy_req.url(req)
    Logger.debug "url: #{inspect url}"

    {method, req} = :cowboy_req.method(req)
    Logger.debug "method: #{inspect method}"

    server = get_random_server
    Logger.debug "forwarding request to #{server.host}, port #{server.port}"

    new_url = Regex.replace(~r/^#{host_url}/, url, "http://#{server.host}:#{server.port}")

    Logger.debug "new_url: #{new_url}"

    options = Application.get_env(:cowboy_playground, :httpoison_config, [])

    Logger.debug "options: #{inspect options}"

    case method do
      "GET" ->
        try do
          {time, {result, response}} = :timer.tc(HTTPoison, :get, [new_url])
          Logger.debug "Call to #{new_url} completed in #{div(time, 1000)}ms."
          Logger.debug "result: #{inspect result}"
          Logger.debug "response: #{inspect response}"
          response_headers = response.headers
                              |> Map.keys
                              |> Enum.map(fn key ->
                                {key, response.headers[key]}
                              end)
          {:ok, req} = :cowboy_req.reply(response.status_code, response_headers, response.body, req)

          {:ok, req, {state, time}}
        rescue
          e ->
            Logger.debug "ERROR! : #{inspect e}"
            {:error, req, {state, 0}}
        end
    end
  end

  def terminate(reason, req, state) do
    start = elem(state, 0)
    req_time = elem(state, 1)

    total_time = :timer.now_diff(:erlang.now(), start)
    Logger.debug "================ in terminate... ================"
    Logger.debug "reason: #{inspect reason}"
    Logger.debug "request: #{inspect req}"
    Logger.debug inspect(state)
    Logger.debug "Total request time: #{inspect(div(total_time, 1000))}ms"
    Logger.debug "Total request time(in router only): #{inspect(div(total_time - req_time, 1000))}ms"
    Logger.debug "================================================="
  end

  defp get_random_server do
    index = :random.uniform(length(@servers)) - 1
    Enum.at(@servers, index)
  end
end