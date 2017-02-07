using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.Models
{
    public class Device
    {
        public bool NodeCompliant;
        public DateTime LastComplianceTime;
        public DateTime LastHeartbeatTime;
        public bool Dirty;
        public Int32 StatusCode;
        public string TargetName;
        public string ConfigurationID;
        public string ServerCheckSum;
        public string TargetChecksum;
    }
}
