require Logger

defmodule CowboyPlayground.RouteLoader do
  import Ecto.Query

  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route
  alias CowboyPlayground.Repo

  @spec start_link() :: {:ok, pid} | {:error, String.t}
  def start_link do
    Logger.debug "Starting the RouteLoader process #{inspect self}"

    # Get the current time for our updater system to use...
    now = Ecto.DateTime.utc

    # Load up the routes from the DB.
    routes = Repo.all(from host in Host,
                      join: route in Route, on: route.host_id == host.id,
                      select: {host.hostname, host.port, route.hostname, route.port})

    Logger.debug(inspect(routes))

    hosts_to_routes = get_route_hashdict(routes)

    Logger.debug(inspect(hosts_to_routes))

    Enum.each(hosts_to_routes, fn({k, v}) ->
      # We can dirty put on initial load, because there won't be any records
      # with matching keys...
      ConCache.dirty_put(:routes, k, v)
    end)

    updater_pid = spawn_link(__MODULE__, :update_routes, [now])

    {:ok, updater_pid}
  end

  def update_routes(last_update) do
    receive do
    after 60000 ->
      Logger.debug "updating routes..."
      now = Ecto.DateTime.utc
      routes = Repo.all(from host in Host,
                        join: route in Route, on: route.host_id == host.id,
                        where: host.updated_at > ^last_update,
                        select: {host.hostname, host.port, route.hostname, route.port})

      Logger.debug "new routes: #{inspect routes}"

      # Overwrite the old routes
      get_route_hashdict(routes)
      |> Enum.each(fn({k, v}) ->
        ConCache.put(:routes, k, v)        
      end)

    end

    update_routes(now)
  end

  defp get_route_hashdict(routes) do
    Enum.reduce(routes, HashDict.new(), fn(tup, dict) ->
      # Tuple: {host hostname, host port, route hostname, route port}
      host = "#{elem(tup, 0)}:#{elem(tup, 1)}"

      HashDict.merge(
        dict,
        HashDict.put(HashDict.new(), host, [{elem(tup, 2), elem(tup, 3)}]),
        fn (key, v1, v2) ->
          v1 ++ v2
        end)
    end)  
  end
end