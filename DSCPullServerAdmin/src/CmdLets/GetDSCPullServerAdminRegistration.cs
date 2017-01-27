using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using DSCPullServerAdmin.src.Models;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Get,"DSCPullServerAdminRegistration")]
    [CmdletBinding()]
    public class GetDSCPullClientNode : PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string ESEPath;
        protected override void ProcessRecord()
        {
            JET_INSTANCE instance;
            JET_SESID sesid;
            JET_DBID dbid;
            JET_TABLEID tableid;

            Api.JetCreateInstance(out instance, "instance");
            Api.JetSetSystemParameter(instance, JET_SESID.Nil, JET_param.CircularLog, 1, null);
            Api.JetInit(ref instance);
            Api.JetBeginSession(instance, out sesid, null, null);

            Api.JetAttachDatabase(sesid, ESEPath, AttachDatabaseGrbit.ReadOnly);
            Api.JetOpenDatabase(sesid, ESEPath, null, out dbid, OpenDatabaseGrbit.ReadOnly);
            Api.JetOpenTable(sesid, dbid, "RegistrationData", null, 0, OpenTableGrbit.ReadOnly, out tableid);

            Api.MoveBeforeFirst(sesid, tableid);
            while (Api.TryMoveNext(sesid, tableid))
            {
                IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                RegistrationData node = new RegistrationData();
                node.AgentId = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AgentId"]);
                node.LCMVersion = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["LCMVersion"]);
                node.NodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                node.IPAddress = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["IPAddress"]).Split(',');
                node.ConfigurationNames = Api.RetrieveColumn(sesid, tableid, columnDictionary["ConfigurationNames"]) as byte[];
                WriteObject(node);
            }
            Api.JetCloseTable(sesid, tableid);
            Api.JetEndSession(sesid, EndSessionGrbit.None);
            Api.JetTerm(instance);
        }
    }
}
