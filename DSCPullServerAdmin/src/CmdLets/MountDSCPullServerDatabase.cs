using DSCPullServerAdmin.src.Helpers;
using Microsoft.Isam.Esent.Interop;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsData.Mount, "DSCPullServerAdminDatabase")]
    public class MountDSCPullServerDatabase : PSCmdlet
    {
        [Parameter(Mandatory = true,
            Position = 0,
                ParameterSetName = "ESE")]
        public FileInfo ESEPath;

        //[Parameter(Mandatory = true,
        //    Position = 0,
        //        ParameterSetName = "MDB")]
        //public FileInfo MDBPath;

        protected override void ProcessRecord()
        {
            if (this.ParameterSetName == "ESE")
            {
                Database.Instance.DatabaseType = DatabaseType.ESE;
                Database.Instance.DatabasePath = ESEPath.ToString();
                Api.JetCreateInstance(out Database.Instance.JetInstance, "instance");
                Api.JetSetSystemParameter(
                    Database.Instance.JetInstance,
                    JET_SESID.Nil,
                    JET_param.CircularLog,
                    1,
                    null);
                Api.JetInit(ref Database.Instance.JetInstance);
                Api.JetBeginSession(
                    Database.Instance.JetInstance,
                    out Database.Instance.SessionId,
                    null,
                    null);
                try
                {
                    Api.JetAttachDatabase(
                        Database.Instance.SessionId,
                        Database.Instance.DatabasePath.ToString(),
                        AttachDatabaseGrbit.None);
                    Api.JetOpenDatabase(
                        Database.Instance.SessionId,
                        Database.Instance.DatabasePath.ToString(),
                        null,
                        out Database.Instance.DBId,
                        OpenDatabaseGrbit.None);
                }
                catch (Exception ex)
                {
                    this.CloseJetDB();
                    ErrorRecord errRecord = new ErrorRecord(
                        ex,
                        ex.Message,
                        ErrorCategory.OpenError,
                        ESEPath.FullName.ToString());
                    this.ThrowTerminatingError(errRecord);
                }
            }
            else
            {
                // MDB implement later
            }
        }

        protected override void StopProcessing()
        {
            if (Database.Instance.DatabaseType == DatabaseType.ESE)
            {
                CloseJetDB();
            }
            else
            {
                // MDB implement later
            }
        }

        private void CloseJetDB()
        {
            Api.JetEndSession(Database.Instance.SessionId, EndSessionGrbit.None);
            Api.JetTerm(Database.Instance.JetInstance);
            Database.Instance.DatabasePath = null;
            Database.Instance.DatabaseType = DatabaseType.None;
            Database.Instance.DBId = JET_DBID.Nil;
            Database.Instance.SessionId = JET_SESID.Nil;
            Database.Instance.JetInstance = JET_INSTANCE.Nil;
        }
    }
}
