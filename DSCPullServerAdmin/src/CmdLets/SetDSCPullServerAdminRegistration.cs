using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using DSCPullServerAdmin.src.Models;
using DSCPullServerAdmin.src.Helpers;
using System.Linq;
using System;
using System.Text;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Set,
        "DSCPullServerAdminRegistration")]
    [OutputType(typeof(void))]
    public class SetDSCPullServerAdminRegistration : BaseCmdlet
    {
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true)]
        [Alias("Id")]
        [ValidateNotNullOrEmpty()]
        public string[] AgentId;

        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty()]
        public string[] Configurations;

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
                        if (AgentId.ToList().Contains(agentId) == false)
                        {
                            continue;
                        }

                        Api.JetBeginTransaction(sesid);

                        Api.JetPrepareUpdate(sesid, tableid, JET_prep.Replace);

                        Api.SerializeObjectToColumn(sesid, tableid, columnDictionary["ConfigurationNames"], Configurations);

                        Api.JetUpdate(sesid, tableid);
                        Api.JetCommitTransaction(sesid,CommitTransactionGrbit.LazyFlush);

                    Api.JetBeginTransaction(sesid);
                    Api.JetPrepareUpdate(sesid, tableid, JET_prep.Replace);

                    string fullString = String.Join(String.Empty, Configurations.ToArray());
                    byte[] byteArray = Encoding.UTF8.GetBytes(fullString);

                    //Api.SetColumn(sesid, tableid, columnDictionary["ConfigurationNames"], byteArray);
                    Api.SerializeObjectToColumn(sesid, tableid, columnDictionary["ConfigurationNames"], Configurations.ToList());
                    Api.JetUpdate(sesid, tableid);
                    Api.JetCommitTransaction(sesid, CommitTransactionGrbit.None);

                }
                }
                else
                {
                    // MDB implement later
                }
        }
    }
}
