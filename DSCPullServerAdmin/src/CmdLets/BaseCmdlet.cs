using System;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using System.IO;
using DSCPullServerAdmin.src.Helpers;

namespace DSCPullServerAdmin.src.CmdLets
{
    [CmdletBinding()]
    public abstract class BaseCmdlet : PSCmdlet, IDisposable
    {
        public JET_TABLEID tableid;
        public JET_SESID sesid = Database.Instance.SessionId;

        public abstract string tableName { get; }

        protected override void BeginProcessing()
        {
            if (Database.Instance.DatabaseType == DatabaseType.ESE)
            {
                Api.JetOpenTable(
                    Database.Instance.SessionId,
                    Database.Instance.DBId,
                    tableName,
                    null,
                    0,
                    OpenTableGrbit.None,
                    out tableid);
            }
            else if (Database.Instance.DatabaseType == DatabaseType.MDB)
            {
                // MDB implement later
            }
            else
            {
                throw new Exception("No database has been mounted yet. Please use Mount-DSCPullServerAdminDatabase.");
            }
        }

        protected override void EndProcessing()
        {
            if (Database.Instance.DatabaseType == DatabaseType.ESE)
                CloseTable();
            else
            {
                // MDB implement later
            }
        }

        protected override void StopProcessing()
        {
            if (Database.Instance.DatabaseType == DatabaseType.ESE)
                CloseTable();
            else
            {
                // MDB implement later
            }
        }

        private void CloseTable ()
        {
            if (tableid.IsInvalid == false)
            {
                Api.JetCloseTable(Database.Instance.SessionId, tableid);
            }
        }

        protected virtual void Dispose(bool disposing)
        {
            try
            {
                if (Database.Instance.DatabaseType == DatabaseType.ESE)
                    this.CloseTable();
                else
                {
                    // MDB implement later
                }

            }
            catch { }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
    }
}
