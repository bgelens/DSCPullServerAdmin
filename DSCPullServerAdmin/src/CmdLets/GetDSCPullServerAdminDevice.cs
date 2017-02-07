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
    [Cmdlet(VerbsCommon.Get,
        "DSCPullServerAdminDevice",
        DefaultParameterSetName = "List")]
    public class GetDSCPullServerAdminDevice : BaseCmdlet
    {
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
