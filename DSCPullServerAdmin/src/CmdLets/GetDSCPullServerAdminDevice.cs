using DSCPullServerAdmin.src.Models;
using Microsoft.Isam.Esent.Interop;
using System.Collections.Generic;
using System.Management.Automation;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Get,
        "DSCPullServerAdminDevice",
        DefaultParameterSetName = "List")]
    [OutputType(typeof(Device))]
    public class GetDSCPullServerAdminDevice : BaseCmdlet
    {
        [Parameter(ParameterSetName = "TargetName")]
        [Alias("Name")]
        [ValidateNotNullOrEmpty()]
        public string TargetName;

        public override string tableName
        {
            get
            {
                return "Devices";
            }
        }
        protected override void ProcessRecord()
        {
            Api.MoveBeforeFirst(sesid, tableid);
            while (Api.TryMoveNext(sesid, tableid))
            {
                IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                if (TargetName != null)
                {
                    string targetName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["TargetName"]);
                    if (targetName != TargetName)
                    {
                        continue;
                    }
                }
                Device device = new Device();
                device.TargetName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["TargetName"]);
                device.ConfigurationID = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["ConfigurationID"]);
                device.ServerCheckSum = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["ServerCheckSum"]);
                device.TargetChecksum = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["TargetChecksum"]);
                if (Api.RetrieveColumnAsBoolean(sesid, tableid, columnDictionary["NodeCompliant"]).HasValue)
                {
                    device.NodeCompliant = Api.RetrieveColumnAsBoolean(sesid, tableid, columnDictionary["NodeCompliant"]).Value;
                }
                if (Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastComplianceTime"]).HasValue)
                {
                    device.LastComplianceTime = Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastComplianceTime"]).Value;
                }
                if (Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastHeartbeatTime"]).HasValue)
                {
                    device.LastHeartbeatTime = Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastHeartbeatTime"]).Value;
                }
                if (Api.RetrieveColumnAsBoolean(sesid, tableid, columnDictionary["Dirty"]).HasValue)
                {
                    device.Dirty = Api.RetrieveColumnAsBoolean(sesid, tableid, columnDictionary["Dirty"]).Value;
                }
                if (Api.RetrieveColumnAsInt32(sesid, tableid, columnDictionary["StatusCode"]).HasValue)
                {
                    device.StatusCode = Api.RetrieveColumnAsInt32(sesid, tableid, columnDictionary["StatusCode"]).Value;
                }
                WriteObject(device);
            }
        }
    }
}
