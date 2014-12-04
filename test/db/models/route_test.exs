defmodule DB.Models.Route.Test do
  use ExUnit.Case

  import Ecto.Query

  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route
  alias CowboyPlayground.Repo

  setup _context do
    host = Repo.insert(%Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})
    host2 = Repo.insert(%Host{hostname: "dev.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc})

    on_exit _context, fn ->
      Repo.delete_all(Route)
      Repo.delete(host)
      Repo.delete(host2)
    end

    {:ok, [host: host, host2: host2]}
  end

  test "host_id, hostname, and port combo must be unique", context do
    host = context[:host]
    route = %Route{host_id: host.id, hostname: "east.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    Repo.insert(route)

    assert_raise Postgrex.Error,
                 "ERROR (23505): duplicate key value violates unique constraint \"routes_host_id_hostname_port_key\"",
                 fn -> Repo.insert(route) end
  end

  test "host_id, hostname, and port combo can be different", context do
    host = context[:host]
    route = %Route{host_id: host.id, hostname: "east.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    Repo.insert(route)

    route1 = %{route | hostname: "west.test"}
    Repo.insert(route1)

    assert length(Repo.all(Route)) == 2

    route2 = %{route | port: 81}
    Repo.insert(route2)

    assert length(Repo.all(Route)) == 3

    host2 = context[:host2]

    route3 = %{route | host_id: host2.id}
    Repo.insert(route3)

    assert length(Repo.all(Route)) == 4
  end

  test "host_id is required" do
    route = %Route{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    result = Route.validate(route)

    assert length(result) != 0
    assert Keyword.has_key?(result, :host_id)
  end

  test "hostname is required", context do
    route = %Route{host_id: context[:host].id, port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    result = Route.validate(route)

    assert length(result) != 0
    assert Keyword.has_key?(result, :hostname)
  end

  test "port is required", context do
    route = %Route{host_id: context[:host].id, hostname: "test", created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    result = Route.validate(route)

    assert length(result) != 0
    assert Keyword.has_key?(result, :port)
  end

  test "created_at timestamp is required", context do
    route = %Route{host_id: context[:host].id, hostname: "test", port: 80, updated_at: Ecto.DateTime.utc}
    result = Route.validate(route)

    assert length(result) != 0
    assert Keyword.has_key?(result, :created_at)
  end

  test "updated_at timestamp is required", context do
    route = %Route{host_id: context[:host].id, hostname: "test", port: 80, created_at: Ecto.DateTime.utc}
    result = Route.validate(route)

    assert length(result) != 0
    assert Keyword.has_key?(result, :updated_at)
  end

  test "retrieve associated host (belongs_to association)", context do
    route = %Route{host_id: context[:host].id, hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    route = Repo.insert(route)

    [route] = Repo.all(from r in Route,
                       where: r.id == ^route.id,
                       preload: :host)

    assert route.host.loaded?
    assert route.host.get == context[:host]
  end
end
