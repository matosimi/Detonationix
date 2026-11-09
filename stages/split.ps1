param(
    [Parameter(Mandatory)][string]$InFile,
    [Parameter(Mandatory)][int]$Size,
    [Parameter(Mandatory)][string]$OutFile
)

$in   = [IO.File]::OpenRead((Resolve-Path $InFile).Path)
$out  = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
$base = Join-Path ([IO.Path]::GetDirectoryName($out)) ([IO.Path]::GetFileNameWithoutExtension($out))
$ext  = [IO.Path]::GetExtension($out)
$buf  = New-Object byte[] $Size
$i    = 0

while (($n = $in.Read($buf, 0, $Size)) -gt 0) {
    $part = [IO.File]::Create(("{0}{1:x2}{2}" -f $base, $i++, $ext))
    $part.Write($buf, 0, $n)
    $part.Close()
}
$in.Close()