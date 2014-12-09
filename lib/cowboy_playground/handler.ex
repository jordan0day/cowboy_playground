require Logger

defmodule CowboyPlayground.Handler do

  def on_request(req) do
    # TODO: Move request handling out of handle and into on_request,
    # which should slightly speed up routing time.
    req
  end

  def init({_transport, _proto_name}, req, opts) do
    start_time = :erlang.now()

    {:ok, req, start_time}
  end

  def handle(req, state) do
    {path, req} = :cowboy_req.path(req)

    if path == "/cloudos_router_status" do
      # Ignore everything else if the request is just the ELB's healthcheck
      req = handle_status_request(req)
      {:ok, req, {state, 0}}
    else
      Logger.debug inspect(req)
      {result, req, time} = handle_request(req, path)
      {result, req, {state, time}}
    end    
  end

  def terminate(_reason, _req, state) do
    start_time = elem(state, 0)
    req_time = elem(state, 1)

    total_time = :timer.now_diff(:erlang.now(), start_time)

    Logger.info "Total request time (time in router): #{inspect(div(total_time, 1000))}ms (#{inspect(div(total_time - req_time, 1000))}ms)"
    :ok
  end

  defp handle_request(req, path) do
    {:ok, body, req} = :cowboy_req.body(req)
    
    # TODO: handle chunked request bodies larger than 8MB. By default, 8MB is
    # the most Cowboy will read from the request.
    # See http://ninenines.eu/docs/en/cowboy/1.0/manual/cowboy_req/#request_body_related_exports

    {cookies, req} = :cowboy_req.cookies(req)

    {headers, req} = :cowboy_req.headers(req)

    {peer, req} = :cowboy_req.peer(req)

    {querystring, req} = :cowboy_req.qs(req)

    {version, req} = :cowboy_req.version(req)

    {host, req} = :cowboy_req.host(req)

    {hostinfo, req} = :cowboy_req.host_info(req)

    {host_url, req} = :cowboy_req.host_url(req)

    {port, req} = :cowboy_req.port(req)

    {forwarded_for, req} = :cowboy_req.header("x-forwarded-for", req, nil)

    {forwarded_port, req} = :cowboy_req.header("x-forwarded-port", req, nil)

    {forwarded_proto, req} = :cowboy_req.header("x-forwarded-proto", req, nil)

    if port == nil do
      port = 80
    end 

    {url, req} = :cowboy_req.url(req)

    {method, req} = :cowboy_req.method(req)

    Logger.debug "Processing #{method} request for #{url}"

    # TODO: Handle when we don't have a route matching what's requested
    # Going with returning 503 here, that seems to be AWS's behavior for an ELB
    # that doesn't have any associated instances.
    case get_random_server(host, port) do
      nil ->
        {:ok, req} = :cowboy_req.reply(503, req)
        {:ok, req, 0}

      {server_host, server_port, use_secure_connection} ->
        proto = if use_secure_connection do
          "https"
        else
          "http"
        end

        new_url = Regex.replace(~r/^#{host_url}/, url, "#{proto}://#{server_host}:#{server_port}")

        method = case method do
          "DELETE" -> :delete
          "GET" -> :get
          "HEAD" -> :head
          "OPTIONS" -> :options
          "PATCH" -> :patch
          "POST" -> :post
          "PUT" -> :put
          other -> 
            # TODO: Decide if we want to reject non-standard request methods, add
            # a whitelist, or something else. This current implementation is
            # unsafe, as an attacker could crash the router by sending many
            # requests with unique methods -- atoms are never garbage collected.
            # See here: http://elixir-lang.org/getting_started/mix_otp/3.html
            other |> String.downcase |> String.to_atom
        end

        try do
          {time, {result, response}} = :timer.tc(HTTPoison, :request, [method, new_url, body, headers])
          Logger.debug "Call to #{new_url} completed with #{inspect result} in #{div(time, 1000)}ms."

          # TODO: We're currently buffering the entire response and sending it in one blob to the client.
          # So we have to delete the transfer-encoding header since it's no longer chunked.
          # We need to fix the router so it doesn't buffer the entire response, but instead sends the
          # chunks back to the client in the order it receives them from the backend.
          response_headers = Map.delete(response.headers, "transfer-encoding")

          {:ok, req} = :cowboy_req.reply(response.status_code, Map.to_list(response_headers), response.body, req)

          {:ok, req, time}
        rescue
          e ->
            Logger.error inspect(e)
            {:error, req, 0}
        end
    end
  end

  defp handle_status_request(req) do
    status = case Agent.get(CowboyPlayground.RouteServer, fn state -> state end) do
      {_started, nil} ->
        # Routes haven't been loaded yet, we can't process requests...
        503
      {_started, last_fetch} ->
        # Todo: Make this TTL configurable
        ttl = 600 # in seconds
        erl_last_fetch = last_fetch |> Ecto.DateTime.to_erl

        now = :erlang.now() |> :calendar.now_to_datetime

        {days, time} = :calendar.time_difference(erl_last_fetch, now)

        if days > 0 || :calendar.time_to_seconds(time) > ttl do
          # If it's been more than *ttl* since we've updated, let's fail
          # this router's health check.
          Logger.error "Routes haven't been updated since #{inspect last_fetch}. Router is not healthy."
          503
        else
          # It's been less than *ttl* since our last update, router
          # seems healthy.
          200
        end

      other ->
        Logger.error "Unexpected result retrieving RouteServer agent state: #{inspect other}"
        503
    end

    Logger.debug "Handling status request from load balancer. Replying with #{inspect status}."
    {:ok, req} = :cowboy_req.reply(status, req)

    req
  end

  defp get_random_server(host, port) do
    routes = ConCache.get(:routes, "#{host}:#{port}")
    Logger.debug "Routes matching #{host}:#{port}: #{inspect routes}"

    case routes do
      nil -> nil
      [route | []] -> route
      routes ->
        index = :random.uniform(length(routes)) - 1
        Enum.at(routes, index)
    end
  end
end