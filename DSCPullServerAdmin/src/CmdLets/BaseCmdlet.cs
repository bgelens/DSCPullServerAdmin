using System;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using System.IO;

namespace DSCPullServerAdmin.src.CmdLets
{
    [CmdletBinding()]
    public abstract class BaseCmdlet : PSCmdlet
    {
        public JET_INSTANCE instance;
        public JET_SESID sesid;
        public JET_DBID dbid;
        public JET_TABLEID tableid;

        public abstract string tableName { get; }

        [Parameter(Mandatory =true,
            Position = 0)]
        public FileInfo ESEPath;

        protected override void BeginProcessing()
        {
            Api.JetCreateInstance(out instance, "instance");
            Api.JetSetSystemParameter(instance, JET_SESID.Nil, JET_param.CircularLog, 1, null);
            Api.JetInit(ref instance);
            Api.JetBeginSession(instance, out sesid, null, null);
            try
            {
                Api.JetAttachDatabase(sesid, ESEPath.FullName.ToString(), AttachDatabaseGrbit.None);
            }
            catch (Exception ex)
            {
                this.ClodeJetDB();
                ErrorRecord errRecord = new ErrorRecord(
                    ex,
                    ex.Message,
                    ErrorCategory.OpenError,
                    ESEPath.FullName.ToString());
                this.ThrowTerminatingError(errRecord);
            }
            Api.JetOpenDatabase(sesid, ESEPath.FullName.ToString(), null, out dbid, OpenDatabaseGrbit.None);
            Api.JetOpenTable(sesid, dbid, tableName, null, 0, OpenTableGrbit.None, out tableid);
        }

        protected override void EndProcessing()
        {
            ClodeJetDB();
        }

        protected override void StopProcessing()
        {
            ClodeJetDB();
        }

        private void ClodeJetDB ()
        {
            if (tableid.IsInvalid == false)
            {
                Api.JetCloseTable(sesid, tableid);
            }
            Api.JetEndSession(sesid, EndSessionGrbit.None);
            Api.JetTerm(instance);
        }
    }
}
