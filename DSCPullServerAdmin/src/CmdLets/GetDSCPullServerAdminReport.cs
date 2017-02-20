using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using System;
using DSCPullServerAdmin.src.Models;
using System.Web.Script.Serialization;
using DSCPullServerAdmin.src.Helpers;

namespace DSCPullServerAdmin.src.CmdLets
{
    [Cmdlet(VerbsCommon.Get,"DSCPullServerAdminReport",
        DefaultParameterSetName = "List")]
    [OutputType(typeof(StatusReport))]
    public class GetDSCPullServerAdminReport : BaseCmdlet
    {
        [Parameter(ParameterSetName = "NodeName")]
        [Alias("Name")]
        [ValidateNotNullOrEmpty()]
        public string NodeName;

        [Parameter(ParameterSetName = "NodeName")]
        [Parameter(ParameterSetName = "List")]
        public DateTime FromStartTime;

        [Parameter(ParameterSetName = "NodeName")]
        [Parameter(ParameterSetName = "List")]
        public DateTime ToStartTime;

        public override string tableName
        {
            get
            {
                return "StatusReport";
            }
        }
        JavaScriptSerializer Serializer = new JavaScriptSerializer();

        protected override void ProcessRecord()
        {
            if (Database.Instance.JetInstance != JET_INSTANCE.Nil)
            {
                Api.MoveBeforeFirst(sesid, tableid);
                while (Api.TryMoveNext(sesid, tableid))
                {
                    IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                    if (NodeName != null)
                    {
                        string nodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                        if (nodeName != NodeName)
                        {
                            continue;
                        }
                    }
                    DateTime StartTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["StartTime"]);
                    if (FromStartTime > StartTime)
                    {
                        continue;
                    }

                    if (ToStartTime != DateTime.MinValue && ToStartTime < StartTime)
                    {
                        continue;
                    }

                    StatusReport report = new StatusReport();
                    report.StartTime = StartTime;
                    report.EndTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["EndTime"]);
                    report.LastModifiedTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastModifiedTime"]);
                    report.JobId = (Guid)Api.RetrieveColumnAsGuid(sesid, tableid, columnDictionary["JobId"]);
                    report.Id = (Guid)Api.RetrieveColumnAsGuid(sesid, tableid, columnDictionary["Id"]);
                    report.OperationType = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["OperationType"]);
                    report.RefreshMode = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["RefreshMode"]);
                    report.Status = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["Status"]);
                    report.LCMVersion = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["LCMVersion"]);
                    report.ReportFormatVersion = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["ReportFormatVersion"]);
                    report.ConfigurationVersion = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["ConfigurationVersion"]);
                    report.NodeName = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["NodeName"]);
                    report.IPAddress = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["IPAddress"]).Split(',');
                    report.RebootRequested = bool.Parse(Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["RebootRequested"]));
                    report.Errors = (List<string>)Api.DeserializeObjectFromColumn(sesid, tableid, columnDictionary["Errors"]);
                    report.StatusData = (List<string>)Api.DeserializeObjectFromColumn(sesid, tableid, columnDictionary["StatusData"]);
                    report.AdditionalData = Serializer.Deserialize<List<PropertyBag>>(Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AdditionalData"]));
                    WriteObject(report);
                }
            }
            else
            {
                // MDB implement later
            }
        }
    }
}
