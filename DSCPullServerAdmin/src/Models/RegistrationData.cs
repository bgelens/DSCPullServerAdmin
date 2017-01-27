using System.Collections.Generic;

namespace DSCPullServerAdmin.src.Models
{
    public class RegistrationData
    {
        public string AgentId;
        public string LCMVersion;
        public string NodeName;
        public string[] IPAddress;
        public List<string> ConfigurationNames;
    }
}
