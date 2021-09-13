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

