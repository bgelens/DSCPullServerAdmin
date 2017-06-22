using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using DSCPullServerAdmin.src.Models;
using DSCPullServerAdmin.src.Helpers;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Remove,
        "DSCPullServerAdminRegistration")]
    [OutputType(typeof(void))]
    public class RemoveDSCPullServerAdminRegistration : BaseCmdlet
    {
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true)]
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
            if (Database.Instance.JetInstance != JET_INSTANCE.Nil)
            {
                Api.MoveBeforeFirst(sesid, tableid);
                while (Api.TryMoveNext(Database.Instance.SessionId, tableid))
                {
                    IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);

                    string agentId = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AgentId"]);
                    if (AgentId != agentId)
                    {
                        continue;
                    }

                    Api.JetDelete(sesid, tableid);
                }
            }
            else
            {
                // MDB implement later
            }
        }
    }
}
