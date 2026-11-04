param([Parameter(Mandatory)][string]$Executable)
$ErrorActionPreference = 'Stop'
$start = [System.Diagnostics.ProcessStartInfo]::new((Resolve-Path -LiteralPath $Executable).Path)
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$process = [System.Diagnostics.Process]::Start($start)
$stderr = $process.StandardError.ReadToEndAsync()
function Invoke-Rpc($id, $method, $parameters) {
    $process.StandardInput.WriteLine((@{jsonrpc='2.0'; id=$id; method=$method; params=$parameters} | ConvertTo-Json -Depth 20 -Compress))
    $line = $process.StandardOutput.ReadLineAsync().WaitAsync([TimeSpan]::FromSeconds(20)).GetAwaiter().GetResult()
    if (!$line) { throw 'Runtime closed stdout' }
    return ($line | ConvertFrom-Json -Depth 30)
}
try {
    $hello = Invoke-Rpc 1 'initialize' @{protocolVersion='2025-06-18'; capabilities=@{}; clientInfo=@{name='pidex-release-check';version='1'}}
    if ($hello.result.serverInfo.name -ne 'CPX-CUA' -or $hello.result.protocolVersion -ne '2025-06-18') { throw 'Incompatible handshake' }
    $process.StandardInput.WriteLine('{"jsonrpc":"2.0","method":"notifications/initialized"}')
    $tools = (Invoke-Rpc 2 'tools/list' @{}).result.tools
    $required = @('cpx_apps','get_window_state','click','double_click','right_click','type_text','press_key','hotkey','scroll','drag','start_session','end_session')
    if ($tools.Count -ne $required.Count) { throw 'Unexpected tool surface' }
    foreach ($name in $required) { if ($name -notin $tools.name) { throw "Missing tool: $name" } }
    if (!(($tools | Where-Object name -EQ 'cpx_apps').'x-cpx-identity-v1')) { throw 'Missing identity capability' }
    $denied = Invoke-Rpc 3 'tools/call' @{name='kill_app';arguments=@{}}
    if (!$denied.error -and !$denied.result.isError) { throw 'Non-allowlisted tool was admitted' }
    $denied = Invoke-Rpc 4 'tools/call' @{name='click';arguments=@{pid=$PID;window_id=1;cpx_window_id='1';cpx_app_id='forged';cpx_process_key='forged';cpx_fingerprint='forged'}}
    if (!$denied.error -and !$denied.result.isError) { throw 'Forged identity was admitted' }
    Write-Output 'CPX-CUA handshake, tool surface and negative identity checks passed'
} finally {
    $process.StandardInput.Close()
    if (!$process.WaitForExit(5000)) { $process.Kill($true); $process.WaitForExit() }
    $process.Dispose()
}
