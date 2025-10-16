# ZDBA - Zabbix Database Agent

**ZDBA** is a lightweight service for collecting and sending database metrics to
Zabbix. It is designed for simplicity, portability, and performance, with
first-class support for JDBC-compatible databases.

## Features

- YAML-based configuration with JSON Schema validation
- Pushes metrics to Zabbix over HTTP(S)
- Multithreaded workers and sender architecture using queues
- Supports shared and externalized item definitions
- Structured JSON logging

## Contributing

1. Clone the repository
    ```bash
    git clone https://github.com/netrusov/zdba.git
    cd zdba
    ```

1. Install [mise](https://github.com/jdx/mise)

1. Setup project
    ```bash
    mise run setup
    ```

## License

MIT License

Copyright (c) 2025 Alexander Netrusov
