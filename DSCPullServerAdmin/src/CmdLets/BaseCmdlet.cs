using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;

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
        public string ESEPath;
        protected override void BeginProcessing()
        {
            Api.JetCreateInstance(out instance, "instance");
            Api.JetSetSystemParameter(instance, JET_SESID.Nil, JET_param.CircularLog, 1, null);
            Api.JetInit(ref instance);
            Api.JetBeginSession(instance, out sesid, null, null);

            Api.JetAttachDatabase(sesid, ESEPath, AttachDatabaseGrbit.None);
            Api.JetOpenDatabase(sesid, ESEPath, null, out dbid, OpenDatabaseGrbit.None);
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
            Api.JetCloseTable(sesid, tableid);
            Api.JetEndSession(sesid, EndSessionGrbit.None);
            Api.JetTerm(instance);
        }
    }
}
