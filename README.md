# ZDBA - Zabbix Database Agent

**ZDBA** is a lightweight service for collecting and sending database metrics to
Zabbix. It is designed for simplicity, portability, and performance, with
first-class support for JDBC-compatible databases.

**NOTE:** this repo is work in progress.

## Install

Using Docker:
```bash
function zdba() {
    docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD:/work" ghcr.io/netrusov/zdba "$@"
}
```

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
