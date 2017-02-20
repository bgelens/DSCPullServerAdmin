using DSCPullServerAdmin.src.Helpers;
using Microsoft.Isam.Esent.Interop;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsData.Dismount, "DSCPullServerAdminDataBase")]
    public class DismountDSCPullServerAdminDatabase : PSCmdlet
    {
        protected override void ProcessRecord()
        {
            if (Database.Instance.DatabaseType == DatabaseType.ESE)
            {
                Api.JetEndSession(Database.Instance.SessionId, EndSessionGrbit.None);
                Api.JetTerm(Database.Instance.JetInstance);
                Database.Instance.DatabasePath = null;
                Database.Instance.DatabaseType = DatabaseType.None;
                Database.Instance.DBId = JET_DBID.Nil;
                Database.Instance.SessionId = JET_SESID.Nil;
                Database.Instance.JetInstance = JET_INSTANCE.Nil;
            }
            else
            {
                //MDB implement later
            }
        }
    }
}
