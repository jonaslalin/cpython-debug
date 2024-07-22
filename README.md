# cpython-debugging

```sh
cp templates/* .
```

```sh
podman build --build-arg-file argfile.conf --security-opt label=disable -t cpython-debugging:latest .
```

```sh
podman run --rm -it cpython-debugging:latest
```
