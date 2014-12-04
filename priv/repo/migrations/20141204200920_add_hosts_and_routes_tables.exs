defmodule CowboyPlayground.Repo.Migrations.AddHostsAndRoutesTables do
  use Ecto.Migration

  def up do
    [
      """
      CREATE TABLE hosts (
        id          SERIAL PRIMARY KEY,
        hostname    varchar(2048) NOT NULL,
        port        integer NOT NULL,
        created_at  timestamp NOT NULL,
        updated_at  timestamp NOT NULL,
        CONSTRAINT  hosts_hostname_port_key UNIQUE(hostname, port))
      """,
      "CREATE INDEX hosts_hostname_port_idx ON hosts(hostname, port)",
      """
      CREATE TABLE routes (
        id          SERIAL PRIMARY KEY,
        host_id     integer NOT NULL REFERENCES hosts,
        hostname    varchar(2048) NOT NULL,
        port        integer NOT NULL,
        created_at  timestamp NOT NULL,
        updated_at  timestamp NOT NULL,
        CONSTRAINT  routes_host_id_hostname_port_key UNIQUE(host_id, hostname, port))
      """,
      "CREATE INDEX routes_host_id_idx ON routes(host_id)"
    ]
  end

  def down do
    [
      "DROP INDEX routes_host_id_idx",
      "DROP TABLE routes",
      "DROP INDEX hosts_hostname_port_idx",
      "DROP TABLE hosts"
    ]
  end
end
