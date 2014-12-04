defmodule DB.Models.Host.Test do
  use ExUnit.Case

  import Ecto.Query

  alias CowboyPlayground.DB.Models.Host
  alias CowboyPlayground.DB.Models.Route
  alias CowboyPlayground.Repo

  setup _context do
    on_exit _context, fn ->
      Repo.delete_all(Host)
    end
  end

  test "hostname and port combo must be unique" do
    host = %Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    Repo.insert(host)

    assert_raise Postgrex.Error,
                 "ERROR (23505): duplicate key value violates unique constraint \"hosts_hostname_port_key\"",
                 fn -> Repo.insert(host) end
  end

  test "hostname and port combo can be different" do
    host1 = %Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    Repo.insert(host1)

    host2 = %{host1 | port: 81}
    Repo.insert(host2)

    assert length(Repo.all(Host)) == 2

    host3 = %{host1 | hostname: "different"}
    Repo.insert(host3)

    assert length(Repo.all(Host)) == 3
  end

  test "hostname is required" do
    host = %Host{port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    result = Host.validate(host)

    assert length(result) != 0
    assert Keyword.has_key?(result, :hostname)
  end

  test "port is required" do
    host = %Host{hostname: "test", created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    result = Host.validate(host)

    assert length(result) != 0
    assert Keyword.has_key?(result, :port)
  end

  test "created_at timestamp is required" do
    host = %Host{hostname: "test", port: 80, updated_at: Ecto.DateTime.utc}
    result = Host.validate(host)

    assert length(result) != 0
    assert Keyword.has_key?(result, :created_at)
  end

  test "updated_at timestamp is required" do
    host = %Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc}
    result = Host.validate(host)

    assert length(result) != 0
    assert Keyword.has_key?(result, :updated_at)
  end

  test "retrieve associated routes" do
    host = %Host{hostname: "test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    host = Repo.insert(host)

    route1 = %Route{host_id: host.id, hostname: "east.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    route1 = Repo.insert(route1)

    route2 = %Route{host_id: host.id, hostname: "west.test", port: 80, created_at: Ecto.DateTime.utc, updated_at: Ecto.DateTime.utc}
    route2 = Repo.insert(route2)

    [host] = Repo.all(from h in Host,
                      where: h.id == ^host.id,
                      preload: :routes)

    assert host.routes.loaded?
    assert length(host.routes.all) == 2

    Repo.delete(route1)
    Repo.delete(route2)
  end
end