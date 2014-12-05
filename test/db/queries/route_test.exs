defmodule DB.Queries.CowboyPlayground.Test do
  use ExUnit.Case

  alias CowboyPlayground.Repo
  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route

  alias CowboyPlayground.DB.Queries.Route, as: RouteQuery

  setup _context do
    host = Repo.insert(%Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    host2 = Repo.insert(%Host{hostname: "dev.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})

    route_1_host_1 = Repo.insert(%Route{host_id: host.id, hostname: "east.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    route_2_host_1 = Repo.insert(%Route{host_id: host.id, hostname: "west.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    route_3_host_1 = Repo.insert(%Route{host_id: host.id, hostname: "north.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    route_4_host_1 = Repo.insert(%Route{host_id: host.id, hostname: "south.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    route_1_host_2 = Repo.insert(%Route{host_id: host2.id, hostname: "east.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    route_2_host_2 = Repo.insert(%Route{host_id: host2.id, hostname: "west.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})

    on_exit _context, fn ->
      Repo.delete_all(Route)
      Repo.delete(host2)
      Repo.delete(host)
    end

    {:ok, [
      host: host,
      host2: host2,
      host1_routes: [
        route_1_host_1,
        route_2_host_1,
        route_3_host_1,
        route_4_host_1],
      host2_routes: [
        route_1_host_2,
        route_2_host_2]]}
  end

  test "find_routes_for_host host 1", context do
    host1_routes = Repo.all(RouteQuery.find_routes_for_host(context[:host].hostname, context[:host].port))

    assert host1_routes == context[:host1_routes]
  end

  test "find_routes_for_host host 2", context do
    host2_routes = Repo.all(RouteQuery.find_routes_for_host(context[:host2].hostname, context[:host2].port))

    assert host2_routes == context[:host2_routes]
  end
end