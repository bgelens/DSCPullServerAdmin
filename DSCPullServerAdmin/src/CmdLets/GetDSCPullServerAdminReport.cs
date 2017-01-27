using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.Isam.Esent.Interop;
using System;
using DSCPullServerAdmin.src.Models;

namespace DSCPullServerAdmin.src.Cmdlets
{
    [Cmdlet(VerbsCommon.Get,"DSCPullServerAdminReport")]
    [CmdletBinding()]
    public class GetDSCPullReport : PSCmdlet
    {
        [Parameter(Mandatory = true)]
        public string ESEPath;
        protected override void ProcessRecord()
        {
            JET_INSTANCE instance;
            JET_SESID sesid;
            JET_DBID dbid;
            JET_TABLEID tableid;

            Api.JetCreateInstance(out instance, "instance");
            Api.JetSetSystemParameter(instance, JET_SESID.Nil, JET_param.CircularLog, 1, null);
            Api.JetInit(ref instance);
            Api.JetBeginSession(instance, out sesid, null, null);

            Api.JetAttachDatabase(sesid, ESEPath, AttachDatabaseGrbit.ReadOnly);
            Api.JetOpenDatabase(sesid, ESEPath, null, out dbid, OpenDatabaseGrbit.ReadOnly);
            Api.JetOpenTable(sesid, dbid, "StatusReport", null, 0, OpenTableGrbit.ReadOnly, out tableid);

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
                //report.Errors = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["Errors"]);
                //report.StatusData = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["StatusData"]);
                //report.AdditionalData = Api.RetrieveColumnAsString(sesid, tableid, columnDictionary["AdditionalData"]);
                WriteObject(report);
            }
            Api.JetCloseTable(sesid, tableid);
            Api.JetEndSession(sesid, EndSessionGrbit.None);
            Api.JetTerm(instance);
        }
    }
}
