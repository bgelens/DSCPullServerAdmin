function Assert-DSCPullServerMDBPreReqs {
    # check on type instead of PowerShell version as potentially the type will surface in a later version when .net core is updated.
    if ($null -eq ('System.Data.OleDb.OleDbConnection'-as [type])) {
        Write-Error -Message 'Type "System.Data.OleDb.OleDbConnection" is not available. To access MDB files, please use PowerShell 5.1' -ErrorAction Stop
    }

    # see if provider is available
    $oleDbEnum = [System.Data.OleDb.OleDbEnumerator]::new()
    if ($oleDbEnum.GetElements().SOURCES_NAME -notcontains 'Microsoft.ACE.OLEDB.16.0') {
        Write-Error -Message 'To access MDB files please install "Microsoft Access Database Engine 2016 Redistributable" from https://www.microsoft.com/en-us/download/details.aspx?id=54920' -ErrorAction Stop
    }
}
