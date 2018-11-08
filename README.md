# heartbeat-operator

A simple Kubernetes operator that operates Elastic [Heartbeat](https://www.elastic.co/products/beats/heartbeat), so that your users can monitor any `http` and `tcp` services running on any infrastructure.

Features:

- Kubernetes custom resources to manage Heartbeat's `http` and `tcp` monitors.
- Supports multiple namespaces i.e. custom resources are namespace-aware. That is, you can restrict your devs to only create custom resources within the namespaces they're responsible.
- Easy installation with helm

## Install

Use the [official heartbeat chart](https://github.com/helm/charts/tree/master/stable/heartbeat), but tweak values to use the alternative docker image for heartbeat-operator, and a custom `config.heartbeat.monitors`.

Beware that the following two sections are necessary in order to feed heartbeat with the "dynamic" monitors created by heartbeat-operator.

For `http` monitors:

```
watch.poll_file:
  path: monitors/httpmonitors.ndjson
```

For `tcp` monitors:

```
tcp.poll_file:
  path: monitors/httpmonitors.ndjson
```


See `example/values.yaml` for more details. You can even try the setup with the yaml file by running:

```
$ make helmrun
```

## Building and testing on minikube

## Run heartbeat-operator within a Kubernetes pod for development purpose

```
$ make build kuberun COMMAND=bash

bash-4.2$ heartbeat-operator -- heartbeat -d '*' -e --plugin kinesis.so
```

## Building and testing on minikube

```
$ make build helmrun
```

In another terminal, create example monitors:

```
$ kubectl create -f example/httpexample.yaml
$ kubectl create -f example/httpexample2.yaml
$ kubectl create -f example/tcpexample.yaml
```

Deploy the monitoring target for the example monitors:

```
$ helm upgrade --install rolling-lion stable/hackmd
```

And watch for logs to see heartbeat recognized the monitors created via the custom resources:

```
2018-07-27T02:43:01.805Z	WARN	beater/heartbeat.go:24	Beta: Heartbeat is beta software
2018-07-27T02:43:01.805Z	INFO	beater/manager.go:110	Select (active) monitor http
2018-07-27T02:43:01.805Z	INFO	beater/manager.go:110	Select (active) monitor tcp
2018-07-27T02:43:01.806Z	ERROR	beater/manager.go:140	failed to load monitor tasks: missing required field accessing 'hosts' when initializing monitor tcp(0)
2018-07-27T02:43:01.806Z	INFO	beater/manager.go:252	load watch object: map[ipv4:true schedule:@every 15s timeout:5s urls:[http://nginx:80]]
2018-07-27T02:43:01.806Z	INFO	beater/manager.go:252	load watch object: map[urls:[http://rolling-lion-hackmd:3000] ipv4:true schedule:@every 10s timeout:5s]
```

Run a sh session within the heartbeat-operator pod in order to verify the monitor results:

```
$ ks get po | grep heart
heartbeat-operator-dhgrs                1/1       Running   0          4m
$ ks exec -it heartbeat-operator-dhgrs sh
$ cat /usr/share/heartbeat/data/heartbeat | tail -n 1
```

```
sh-4.2# cat /usr/share/heartbeat/data/heartbeat | grep nginx | grep http | tail -n 1
```

would print the latest `http` event(note that this is prettified for readability):

```json
{
  "@timestamp": "2018-11-08T01:31:15.936Z",
  "@metadata": {
    "beat": "heartbeat",
    "type": "doc",
    "version": "6.4.0"
  },
  "http": {
    "url": "http://nginx:80"
  },
  "tcp": {
    "port": 80
  },
  "fields": {
    "name": "example-http-monitor",
    "namespace": "default"
  },
  "host": {
    "name": "heartbeat-operator-dhgrs",
  },
  "beat": {
    "name": "heartbeat-operator-dhgrs",
    "hostname": "heartbeat-operator-dhgrs",
    "version": "6.4.0"
  },
  "monitor": {
    "id": "http@http://nginx:80",
    "scheme": "http",
    "name": "http",
    "type": "http",
    "host": "nginx",
    "duration": {
      "us": 48211
    },
    "status": "down"
  },
  "resolve": {
    "host": "nginx"
  },
  "error": {
    "type": "io",
    "message": "lookup nginx on 10.96.0.10:53: server misbehaving"
  }
}
```

And

```
sh-4.2# cat /usr/share/heartbeat/data/heartbeat | grep nginx | grep tcp | tail -n 1
```

would print the latest `tcp` event(note that this is prettified for readability):

```json
{
  "@timestamp": "2018-11-08T01:31:15.936Z",
  "@metadata": {
    "beat": "heartbeat",
    "type": "doc",
    "version": "6.4.0"
  },
  "fields": {
    "namespace": "default",
    "name": "example-tcp-monitor"
  },
  "host": {
    "name": "heartbeat-operator-dhqrs"
  },
  "beat": {
    "version": "6.4.0",
    "name": "heartbeat-operator-dhqrs",
    "hostname": "heartbeat-operator-dhgrs"
  },
  "error": {
    "message": "lookup nginx on 10.96.0.10:53: server misbehaving",
    "type": "io"
  },
  "monitor": {
    "name": "tcp",
    "type": "tcp",
    "host": "nginx",
    "duration": {
      "us": 49174
    },
    "status": "down",
    "id": "tcp-tcp@nginx:80",
    "scheme": "tcp"
  },
  "resolve": {
    "host": "nginx"
  }
}
```

Let's grep for the second `http` example thisn time:

```
sh-4.2# cat /usr/share/heartbeat/data/heartbeat | grep hackmd | tail -n 1
```

```json
{"@timestamp":"2018-07-27T02:48:21.808Z","@metadata":{"beat":"heartbeat","type":"doc","version":"6.3.1"},"error":{"type":"io","message":"lookup rolling-lion-hackmd on 10.96.0.10:53: no such host"},"http":{"url":"http://rolling-lion-hackmd:3000"},"tcp":{"port":3000},"type":"monitor","beat":{"name":"heartbeat-operator-dhgrs","hostname":"heartbeat-operator-dhgrs","version":"6.3.1"},"host":{"name":"heartbeat-operator-dhgrs"},"monitor":{"duration":{"us":23021},"id":"http@http://rolling-lion-hackmd:3000","scheme":"http","name":"http","type":"http","host":"rolling-lion-hackmd","status":"down"},"resolve":{"host":"rolling-lion-hackmd"}}
```
