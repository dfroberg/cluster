# Kubed Annotations
Source: https://appscode.com/products/kubed/v0.12.0/guides/config-syncer/intra-cluster/

## Synchronize Configuration across Namespaces
Say, you are using some Docker private registry. You want to keep its image pull secret synchronized across all namespaces of a Kubernetes cluster. Kubed can do that for you. If a ConfigMap or a Secret has the annotation ```kubed.appscode.com/sync: ""```, Kubed will create a copy of that ConfigMap/Secret in all existing namespaces. Kubed will also create this ConfigMap/Secret, when you create a new namespace.

If you want to synchronize ConfigMap/Secret to some selected namespaces instead of all namespaces, you can do that by specifying namespace label-selector in the annotation. For example: ```kubed.appscode.com/sync: "app=kubed"```. Kubed will create a copy of that ConfigMap/Secret in all namespaces that matches the label-selector. Kubed will also create this Configmap/Secret in newly created namespace if it matches the label-selector.

If the data in the source ConfigMap/Secret is updated, all the copies will be updated. Either delete the source ConfigMap/Secret or remove the annotation from the source ConfigMap/Secret to remove the copies. If the namespace with the source ConfigMap/Secret is deleted, the copies will also be deleted.

If the value of label-selector specified by annotation is updated, Kubed will synchronize the ConfigMap/Secret accordingly, ie. it will create ConfigMap/Secret in the namespaces that are selected by new label-selector (if not already exists) and delete from namespaces that were synced before but not selected by new label-selector.

Example:
~~~
kubectl annotate configmap omni kubed.appscode.com/sync="" -n demo
~~~
~~~
configmap "omni" annotated
~~~
~~~
kubectl annotate configmap omni kubed.appscode.com/sync="app=kubed" -n demo --overwrite
~~~~
~~~~
configmap "omni" annotated
~~~~
Now Label the TARGET namespaces
~~~~
kubectl label namespace other app=kubed
~~~~
~~~~
namespace "other" labeled
~~~~

## Restricting Source Namespace
By default, Kubed will watch all namespaces for configmaps and secrets with ```kubed.appscode.com/sync``` annotation. But you can restrict the source namespace for configmaps and secrets by changing ```config.configSourceNamespace``` value during installation

## Remove Annotation
Now, lets’ remove the annotation from source ConfigMap omni. Please note that - after annotation key ```kubed.appscode.com/sync-```. This tells kubectl to remove this annotation from ConfigMap omni.
```
kubectl annotate configmap omni kubed.appscode.com/sync- -n demo
```
```
configmap "omni" annotated
```

# Certmanager Templates
Update your wildcard certificate (and or others) to look like this;
~~~
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: "${SECRET_DOMAIN//./-}"
  namespace: networking
spec:
  secretName: "${SECRET_DOMAIN//./-}-tls"
  secretTemplate:
    annotations:
      kubed.appscode.com/sync: "app=kubed"
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: "${SECRET_DOMAIN}"
  dnsNames:
    - "${SECRET_DOMAIN}"
    - "*.${SECRET_DOMAIN}"
~~~