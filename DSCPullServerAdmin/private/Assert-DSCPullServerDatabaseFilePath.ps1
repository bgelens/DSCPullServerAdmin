function Assert-DSCPullServerDatabaseFilePath {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.IO.FileInfo] $File,

        [Parameter(Mandatory)]
        [ValidateSet('ESE', 'MDB')]
        [string] $Type
    )
    process {
        if ($Type -eq 'ESE' -and $File -notmatch '\.edb$') {
            throw 'The file specified in the path argument must be of type edb'
        }

        if ($Type -eq 'MDB' -and $File -notmatch '\.mdb$') {
            throw 'The file specified in the path argument must be of type mdb'
        }

        $true
    }
}
