defmodule CowboyPlayground.DB.Queries.Route do
  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route

  import Ecto.Query
  
  @spec find_routes_for_host(String.t, integer) :: Ecto.Query.t
  def find_routes_for_host(hostname, port) do
    from host in Host,
      join: route in Route, on: route.host_id == host.id,
      where: host.hostname == ^hostname and host.port == ^port,
      select: route
  end
end