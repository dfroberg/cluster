# Just some quick notes
Clone vpa git repo
~~~
git clone https://github.com/kubernetes/autoscaler.git
~~~
Copy to correct path in cluster repo
~~~
cp -r autoscaler/vertical-pod-autoscaler/deploy ../cluster/cluster/core/vpa
~~~
Add vpa directory to the core/kustomization.yaml


Now modify this file to spit out a file instead of apply directly to the cluster;
~~~
/home/dfroberg/autoscaler/vertical-pod-autoscaler/pkg/admission-controller/gencerts.sh
~~~
Make the kubectl line match this:ish depending on paths etc...
~~~
kubectl create secret --namespace=kube-system generic vpa-tls-certs --from-file=${TMP_DIR}/caKey.pem --from-file=${TMP_DIR}/caCert.pem --from-file=${TMP_DIR}/serverKey.pem --from-file=${TMP_DIR}/serverCert.pem --dry-run=client -o yaml | tee ~/cluster/cluster/core/vpa/vpa-tls-certs.sops.yaml
~~~

Since I'm laxy I also modified;
/home/dfroberg/autoscaler/vertical-pod-autoscaler/hack/vpa-process-yamls.sh

And added an extra if;
~~~
if [ ${ACTION} == print ] ; then
      (bash ${SCRIPT_ROOT}/pkg/admission-controller/gencerts.sh || true)
    elif [ ${ACTION} == create ] ; then
~~~

Once that's done, just run;
~~~
./hack/vpa-process-yamls.sh print
~~~

Then encrypt the resulting file;
~~~
sops -i -e /home/dfroberg/cluster/cluster/core/vpa/vpa-tls-certs.sops.yaml
~~~

Commit & push and see it come up
~~~ 
kubectl --namespace=kube-system get pods|grep vpa
vpa-admission-controller-6cd546c4f-5cfz4   1/1     Running   0          16m
vpa-recommender-6855ff754-l4ct5            1/1     Running   0          47m
vpa-updater-998bd8df9-8khbb                1/1     Running   0          47m
~~~
~~~
kubectl get customresourcedefinition|grep verticalpodautoscalers
verticalpodautoscalers.autoscaling.k8s.io                   2021-09-07T08:19:22Z
~~~