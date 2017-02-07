using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using DSCPullServerAdmin.src.Models;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Get,
        "DSCPullServerAdminRegistration",
        DefaultParameterSetName = "List")]
    [OutputType(typeof(RegistrationData))]
    public class GetDSCPullServerAdminRegistration : BaseCmdlet
    {
        [Parameter(ParameterSetName = "NodeName")]
        [Alias("Name")]
        [ValidateNotNullOrEmpty()]
        public string NodeName;

        [Parameter(ParameterSetName = "AgentId")]
        [Alias("Id")]
        [ValidateNotNullOrEmpty()]
        public string AgentId;

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
                if (NodeName != null)
                {
                    string nodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                    if (nodeName != NodeName)
                    {
                        continue;
                    }
                }

                if (AgentId != null)
                {
                    string agentId = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AgentId"]);
                    if (AgentId != agentId)
                    {
                        continue;
                    }
                }
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
