function Mount-DSCPullServerESEDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [ValidateSet('None', 'ReadOnly', 'Exclusive')]
        [string] $Mode = 'None'
    )

    $instanceName = [guid]::NewGuid().guid
    $systemPath = (Split-Path -Path $Connection.ESEFilePath) + '\'

    [Microsoft.Isam.Esent.Interop.JET_INSTANCE] $jetInstance = [Microsoft.Isam.Esent.Interop.JET_INSTANCE]::Nil
    [Microsoft.Isam.Esent.Interop.JET_SESID] $sessionId = [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil
    [Microsoft.Isam.Esent.Interop.JET_DBID] $dbId = [Microsoft.Isam.Esent.Interop.JET_DBID]::Nil

    #parameter options:
    #https://msdn.microsoft.com/en-us/library/microsoft.isam.esent.interop.jet_param(v=exchg.10).aspx

    'NoInformationEvent', 'CircularLog' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            1,
            $null
        )
    }

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
        $jetInstance,
        [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
        [Microsoft.Isam.Esent.Interop.JET_param]::LogFileSize,
        128,
        $null
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
        $jetInstance,
        [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
        [Microsoft.Isam.Esent.Interop.JET_param]::CheckpointDepthMax,
        524288,
        $null
    )

    'PreferredVerPages', 'MaxVerPages' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            1024,
            $null
        )
    }

    'SystemPath', 'TempPath', 'LogFilePath' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            $null,
            $systemPath
        )
    }

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetCreateInstance2(
        [ref]$jetInstance,
        $instanceName,
        $instanceName,
        [Microsoft.Isam.Esent.Interop.CreateInstanceGrbit]::None
    )


    [void] [Microsoft.Isam.Esent.Interop.Api]::JetInit2(
        [ref]$jetInstance,
        [Microsoft.Isam.Esent.Interop.InitGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetBeginSession(
        $jetInstance,
        [ref]$sessionId,
        $null,
        $null
    )
    try {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetAttachDatabase(
            $sessionId,
            $Connection.ESEFilePath,
            [Microsoft.Isam.Esent.Interop.AttachDatabaseGrbit]$Mode
        )
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenDatabase(
            $sessionId,
            $Connection.ESEFilePath,
            $null,
            [ref]$dbId,
            [Microsoft.Isam.Esent.Interop.OpenDatabaseGrbit]$Mode
        )
        $Connection.Instance = $jetInstance
        $Connection.SessionId = $sessionId
        $Connection.DbId = $dbId
    } catch {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetEndSession(
            $sessionId,
            [Microsoft.Isam.Esent.Interop.EndSessionGrbit]::None
        )
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetTerm($jetInstance)
        throw $_
    }
}
