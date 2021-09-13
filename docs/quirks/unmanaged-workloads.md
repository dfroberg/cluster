# Unmanaged workloads

Say you wish to launch a manually managed workload into your cluster that you want FluxCD to ignore, add this annotation to it and it will be left alone;

~~~yaml
annotations:
  fluxcd.io/ignore: "true"
~~~

