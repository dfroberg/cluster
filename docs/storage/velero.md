# Configure Veleo
Install the velero-cli

## Install GitHub release
Download the latest release’s tarball for your client platform.
https://github.com/vmware-tanzu/velero/releases/latest

I.e;
curl -L https://github.com/vmware-tanzu/velero/releases/download/v1.6.3/velero-v1.6.3-linux-amd64.tar.gz --output velero.tar.gz

Extract the tarball:

tar -xvf velero.tar.gz
Move the extracted velero binary to somewhere in your $PATH (/usr/local/bin for most users).

sudo cp velero-v1.6.3-linux-amd64/velero /usr/local/bin/

## Apply secrets:

Clean out and re-encrypt ./cluster/apps/velero/secret.sops.yaml modify content to read;
~~~
stringData:
  cloud: |
    [default]
    aws_access_key_id=<secret>
    aws_secret_access_key=<not going to tell>
~~~

## Check Installation
~~~
velero version
~~~
~~~
Client:
        Version: v1.6.3
        Git commit: 5fe3a50bfddc2becb4c0bd5e2d3d4053a23e95d2
Server:
        Version: v1.6.3
~~~

~~~
velero backup-location get
~~~
~~~
NAME      PROVIDER   BUCKET/PREFIX   PHASE         LAST VALIDATED                   ACCESS MODE   DEFAULT
default   aws        velero          Unavailable   2021-09-13 11:21:08 +0200 CEST   ReadWrite     true
~~~
Ooops if you see **Unavailable** check MinIO if you remebered to create the bucket or if s3Url is ok...
Once you fixed everything:
~~~
NAME      PROVIDER   BUCKET/PREFIX   PHASE       LAST VALIDATED                   ACCESS MODE   DEFAULT
default   aws        velero          Available   2021-09-13 11:28:26 +0200 CEST   ReadWrite     true
~~~
Taaadaa **Available**!

Check if you're schedule is set;
~~~
velero get schedules
~~~
~~~
NAME                  STATUS    CREATED                          SCHEDULE    BACKUP TTL   LAST BACKUP   SELECTOR
velero-daily-backup   Enabled   2021-09-13 11:16:59 +0200 CEST   0 6 * * *   120h0m0s     14m ago       <none>
~~~

Check if backups are succeding;
~~~
velero get backups
~~~
~~~
NAME                                 STATUS      ERRORS   WARNINGS   CREATED                          EXPIRES   STORAGE LOCATION   SELECTOR
velero-daily-backup-20210913114258   Completed   0        0          2021-09-13 11:42:58 +0200 CEST   4d        default            <none>
~~~

# Annotations
To enable PV backups on workloads you need to describe in an annotation which volumes to backup;
In manfifests add;
~~~
apiVersion: v1
kind: Pod
metadata:
  annotations:
    backup.velero.io/backup-volumes: data
~~~

or from kubectl;
Examples;
~~~
kubectl -n YOUR_POD_NAMESPACE annotate pod/YOUR_POD_NAME backup.velero.io/backup-volumes=YOUR_VOLUME_NAME_1,YOUR_VOLUME_NAME_2,...
~~~
~~~
kubectl -n default annotate pod hajimari-696b7f8d7d-jf8jh backup.velero.io/backup-volumes=data 
~~~

# Backups
## Entire namespace
~~~
velero backup create backup-demo-app-ns --include-namespaces demo-ns --wait
~~~

