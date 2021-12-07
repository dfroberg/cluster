# Using ESXi
https://github.com/josenk/terraform-provider-esxi

Manual TBD
https://developer.vmware.com/web/tool/4.4.0/ovf

** If you get ESXi Access to resource settings on the host is restricted to the server that is managing it

You need to stop communication between the vCenter Server and the host by stopping the below services. To do so, you need to either login to the console or SSH to the ESXi host. (To enable SSH on your ESXi host, follow the article share at the end of the resolution step)
~~~
/etc/init.d/vpxa stop
~~~
~~~
/etc/init.d/hostd restart
~~~
When these commands are executed, the ESXi host will stop communicating with the vCenter Server.
~~~
terraform apply
~~~
Once your terraform is deployed,  start the VPXA service to add the ESXi host back to vCenter Server.]
~~~
/etc/init.d/vpxa start
~~~
