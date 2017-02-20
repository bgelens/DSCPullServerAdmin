using Microsoft.Isam.Esent.Interop;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DSCPullServerAdmin.src.Helpers
{
    enum DatabaseType
    {
        None,
        ESE,
        MDB
    }
    internal sealed class Database
    {
        private static volatile Database instance;
        private static object lockObject = new Object();
        public DatabaseType DatabaseType;
        public string DatabasePath;
        public JET_INSTANCE JetInstance = JET_INSTANCE.Nil;
        public JET_SESID SessionId = JET_SESID.Nil;
        public JET_DBID DBId = JET_DBID.Nil;

        private Database() { }

        public static Database Instance
        {
            get
            {
                if (instance == null)
                {
                    lock (lockObject)
                    {
                        if (instance == null)
                        {
                            instance = new Database();
                        }
                    }
                }
                return instance;
            }
        }
    }
}
