function Assert-DSCPullServerESEPreReq {
    # see if type is already available, don't load when already loaded
    if ($null -eq ('Microsoft.Isam.Esent.Interop.Api'-as [type])) {
        # try to load
        try {
            [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.Isam.Esent.Interop')
        } catch {
            Write-Error -Message 'To access EDB files, please use PowerShell on Windows' -ErrorAction Stop
        }
    }
}
