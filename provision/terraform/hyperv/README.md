# Enable remote access
Run this in an elevated PowerShell concole;
~~~
Enable-PSRemoting –Force
~~~

Enable the ANONYMOUS LOGON account to perform remote management. On the remote system (the one where you will be running the console):

* Click Start and type dcomcnfg.exe and, when the executable is located by search, press [Enter].
* Expand Component Services.
* Expand Computers.
* Right-click My Computer and click Properties.
* Switch to the COM Security tab and click the Edit Limits button in the Access Permissions section.
* Highlight the ANONYMOUS LOGON entry. Check Allow in the Remote Access row: