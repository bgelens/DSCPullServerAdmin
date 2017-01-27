using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using System;
using DSCPullServerAdmin.src.Models;
using DSCPullServerAdmin.src.CmdLets;

namespace DSCPullServerAdmin.src.Cmdlets
{
    [Cmdlet(VerbsCommon.Get,"DSCPullServerAdminReport")]
    public class GetDSCPullReport : BaseCmdlet
    {
        public override string tableName
        {
            get
            {
                return "StatusReport";
            }
        }
        protected override void ProcessRecord()
        {
            Api.MoveBeforeFirst(sesid, tableid);
            while (Api.TryMoveNext(sesid, tableid))
            {
                IDictionary<string, JET_COLUMNID> columnDictionary = Api.GetColumnDictionary(sesid, tableid);
                StatusReport report = new StatusReport();
                report.StartTime = (DateTime) Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["StartTime"]);
                report.EndTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["EndTime"]);
                report.LastModifiedTime = (DateTime)Api.RetrieveColumnAsDateTime(sesid, tableid, columnDictionary["LastModifiedTime"]);
                report.JobId = (Guid) Api.RetrieveColumnAsGuid(sesid, tableid, columnDictionary["JobId"]);
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
                //report.AdditionalData = (List<PropertyBag>)Api.DeserializeObjectFromColumn(sesid, tableid, columnDictionary["AdditionalData"]);
                WriteObject(report);
            }
        }
    }
}
