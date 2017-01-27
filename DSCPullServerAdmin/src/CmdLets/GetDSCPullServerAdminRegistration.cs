using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using DSCPullServerAdmin.src.Models;
using System.Text;
using System;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Get,"DSCPullServerAdminRegistration")]
    public class GetDSCPullClientNode : BaseCmdlet
    {
        public override string tableName
        {
            get
            {
                return "RegistrationData";
            }
        }
        
        protected override void ProcessRecord()
        {
            Api.MoveBeforeFirst(sesid, tableid);
            while (Api.TryMoveNext(sesid, tableid))
            {
                IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                RegistrationData node = new RegistrationData();
                node.AgentId = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AgentId"]);
                node.LCMVersion = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["LCMVersion"]);
                node.NodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                node.IPAddress = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["IPAddress"]).Split(',');
                node.ConfigurationNames = (List<string>)Api.DeserializeObjectFromColumn(sesid, tableid, columnDictionary["ConfigurationNames"]);
                WriteObject(node);
            }
        }
    }
}
