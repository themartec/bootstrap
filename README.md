# Bootstrap

[![Build Checks
](https://github.com/themartec/bootstrap/actions/workflows/build-checks.yml/badge.svg)
](https://github.com/themartec/bootstrap/actions/workflows/build-checks.yml)

Publicly visible bootstrap and environment checking scripts.

## TL;DR

```sh
/bin/bash -c \
  "$(curl -fsSL \
  https://raw.githubusercontent.com/themartec/bootstrap/refs/heads/master/mise-tasks/pre-check-env.sh)"
```

or if you have it downloaded locally

```sh
make
make build
mise run pre-check-env
```
