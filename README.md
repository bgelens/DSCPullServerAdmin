# DSCPullServerAdmin

master|dev|psgallery
------|---|---------
[![Build status](https://ci.appveyor.com/api/projects/status/4xuee8cuu6p8bs9i/branch/master?svg=true)](https://ci.appveyor.com/project/bgelens/dscpullserveradmin/branch/master)|[![Build status](https://ci.appveyor.com/api/projects/status/4xuee8cuu6p8bs9i/branch/dev?svg=true)](https://ci.appveyor.com/project/bgelens/dscpullserveradmin/branch/dev)| [![PowerShell Gallery](https://img.shields.io/powershellgallery/v/dscpullserveradmin.svg)](https://www.powershellgallery.com/packages/dscpullserveradmin)
[![codecov](https://codecov.io/gh/bgelens/DSCPullServerAdmin/branch/master/graph/badge.svg)](https://codecov.io/gh/bgelens/DSCPullServerAdmin/branch/master)|[![codecov](https://codecov.io/gh/bgelens/DSCPullServerAdmin/branch/dev/graph/badge.svg)](https://codecov.io/gh/bgelens/DSCPullServerAdmin/branch/dev)|

A module to work with the DSC PullServer EDB (ESENT), MDB (Access) and SQL databases and provide a better Admin oriented Pull Server experience.

**Update 12/11/2018:** As of version 0.4.0, the module is able to handle MDB Databases! (For now this requires Windows PowerShell with an additional installation of [Microsoft Access Database Engine 2016 Redistributable](https://www.microsoft.com/en-us/download/details.aspx?id=54920))

**Update 11/20/2018:** As of version 0.3.0, the module is able to handle the EDB with all features again. Get/Set/Remove/New is (in experimental) support!

The module enables you to move data from the EDB or MDB database to a SQL database. This allows you to "upgrade" your Pull Server implementation to make use of the SQL backend introduced in Windows Server RS4 (1803) and Server 2019. It is also capable of doing migrations from any source database type to any destination database type as of version 0.3.0!

The module supports accessing, manipulating, removing Devices (Legacy LCMv1, ConfigurationId), Registrations (LCMv2, AgentId) and StatusReports (LCMv2). All this data can be easily moved over to SQL as well.

**Note that the current state of this module is experimental. Use at your own risk and if possible always create a backup!**

## Thanks!!

A big thank you goes out to [@rdbartram](https://github.com/rdbartram/) and [@gaelcolas](https://github.com/gaelcolas/) who both brought in some major contributions. Thank you both!

## Examples

### EDB

Connect with EDB (the database cannot be in use by another process!) and get Devices and Registrations out of it.

![edb01](/images/edb01.png)

Get StatusReports out of the EDB.

![edb02](/images/edb02.png)

![edb03](/images/edb03.png)

### SQL

Connect with SQL and Get, Set, Create and Remove data.

![sql01](/images/sql01.png)

![sql02](/images/sql02.png)

![sql03](/images/sql03.png)

### Copy Data EDB to SQL

All data can be copied over.

**Note**, the function has been renamed to ```Copy-DSCPullServerAdminData``` as it is now capable of handling any source database type to any destination database type!

![edb2sql01](/images/edb2sql01.png)

![edb2sql02](/images/edb2sql02.png)

## Class diagram

This project is PowerShell class based. Find here the Class diagram structure:

![Diagram](/images/ClassDiagram.png)
