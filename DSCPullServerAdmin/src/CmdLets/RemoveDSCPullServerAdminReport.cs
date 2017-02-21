using DSCPullServerAdmin.src.Helpers;
using DSCPullServerAdmin.src.Models;
using Microsoft.Isam.Esent.Interop;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Remove, "DSCPullServerAdminReport",
        ConfirmImpact = ConfirmImpact.High,
            SupportsShouldProcess = true,
                DefaultParameterSetName = "InputObject")]
    public class RemoveDSCPullServerAdminReport : BaseCmdlet
    {
        [Parameter(ValueFromPipeline = true,
            ParameterSetName = "InputObject")]
        public StatusReport InputObject;

        [Parameter(Mandatory = true,
            ParameterSetName = "StartTime")]
        public DateTime ToStartTime;

        [Parameter(ParameterSetName = "StartTime")]
        public DateTime FromStartTime;

        public override string tableName
        {
            get
            {
                return "StatusReport";
            }
        }

        protected override void ProcessRecord()
        {
            if (Database.Instance.JetInstance != JET_INSTANCE.Nil)
            {
                Api.MoveBeforeFirst(sesid, tableid);
                while (Api.TryMoveNext(sesid, tableid))
                {
                    IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                    Guid JobId = (Guid)Api.RetrieveColumnAsGuid(sesid, tableid, columnDictionary["JobId"]);
                    string nodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                    DateTime StartTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["StartTime"]);

                    if (this.ParameterSetName == "InputObject" && 
                        InputObject.JobId != JobId)
                    {
                        continue;
                    }
                    
                    if (this.ParameterSetName == "StartTime" && 
                        FromStartTime > StartTime)
                    {
                        continue;
                    }
                    if (this.ParameterSetName == "StartTime" && 
                        ToStartTime != DateTime.MinValue && 
                        ToStartTime < StartTime)
                    {
                        continue;
                    }

                    if (ShouldProcess(JobId.ToString() + 
                        " " + StartTime.ToLocalTime().ToString() +
                        " " + nodeName, "Remove"))
                    {
                        Api.JetDelete(sesid, tableid);
                    }
                }
            }
        }
    }
}
