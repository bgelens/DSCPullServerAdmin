using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.Models
{
    public class StatusReport
    {
        public DateTime StartTime;
        public DateTime EndTime;
        public DateTime LastModifiedTime;
        public Guid JobId;
        public Guid Id;
        public string OperationType;
        public string RefreshMode;
        public string Status;
        public string LCMVersion;
        public string ReportFormatVersion;
        public string ConfigurationVersion;
        public string NodeName;
        public string[] IPAddress;
        public bool RebootRequested;
        public List<string> Errors;
        public List<string> StatusData;
        public List<PropertyBag> AdditionalData;
    }
}

public class PropertyBag
{
    public string Key
    {
        get;
        set;
    }

    public string Value
    {
        get;
        set;
    }
}