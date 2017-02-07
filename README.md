# DSCPullServerAdmin
An attempt to interface with DSC Pull Server devices.edb

Primary goals:
- [x] Access reports more easily
- [x] Access v2 registered node information
- [x] Access v1 node information
- [ ] Change node ConfigurationName server side\*<br/>
\*edb file is locked when Pull Server is active. Probably won't work. For Get operations, maybe use VSS snapshotting if edb is locked

Secondary goals:
- [ ] Do the same with mdb :-)
- [ ] Convert from edb to mdb
- [ ] Convert from mdb to edb

![InitialCmdletOutput](images/initialcmdletoutput.png)