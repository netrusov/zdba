# ZDBA - Zabbix Database Agent

**ZDBA** is a lightweight service for collecting and sending database metrics to
Zabbix. It is designed for simplicity, portability, and performance, with
first-class support for JDBC-compatible databases.

This project is a rewrite of my original
[ZabbixDBA](https://github.com/netrusov/ZabbixDBA), with a stronger focus on
making installation, deployment, and configuration simpler.

JRuby was chosen mainly for its access to the broader JVM ecosystem, and JDBC
in particular. In practice, that means database driver setup is usually just a
matter of downloading the vendor JAR and referencing it in the config.

**NOTE:** this repo is work in progress.

## Installation

Using GitHub releases:

```bash
# using wget
wget "https://github.com/netrusov/zdba/releases/latest/download/zdba.jar"

# or using curl
curl -L "https://github.com/netrusov/zdba/releases/latest/download/zdba.jar" -o zdba.jar
```

Using Docker:

```bash
function zdba() {
    docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD:/work" ghcr.io/netrusov/zdba "$@"
}
```

## Usage

Basic setup:

```bash
java -jar zdba.jar init .
java -jar zdba.jar start -c config.yml
```

Using the Docker wrapper:

```bash
zdba init .
zdba start -c config.yml
```

For more commands and options:

```bash
java -jar zdba.jar help
```

Custom queries: Add your own items under `databases[].items` in `config.yml`.

```yaml
databases:
  - name: mydb
    connection:
      database: "postgresql://..."
      username: "..."
      password: "..."
    items:
      - name: my_metric
        query: |
          SELECT count(*) FROM my_table
```

Basic items should return a single value. For additional item types and
examples, refer to the templates under `templates/`.

## Contributing

1. Install [mise](https://github.com/jdx/mise)

1. Clone the repository

   ```bash
   git clone https://github.com/netrusov/zdba.git
   cd zdba
   ```

1. Setup project
   ```bash
   mise run setup
   ```

## License

MIT License

Copyright (c) 2025 Alexander Netrusov
