#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$win32Sig = @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   public static extern bool  ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("uxtheme.dll", CharSet = CharSet.Unicode)] public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
'@
try {
    if (-not ([System.Management.Automation.PSTypeName]'DnsMgr.Win32Con').Type) {
        [void](Add-Type -MemberDefinition $win32Sig -Name 'Win32Con' -Namespace 'DnsMgr' -PassThru)
    }
    $ch = [DnsMgr.Win32Con]::GetConsoleWindow()
    if ($ch -ne [IntPtr]::Zero) { [void][DnsMgr.Win32Con]::ShowWindow($ch, 0) }
} catch {}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    try {
        Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"") -Verb RunAs
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Ung dung can quyen Administrator de thay doi DNS he thong.", "Yeu cau Admin", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
    exit
}

$script:Theme = @{
    BG       = [System.Drawing.ColorTranslator]::FromHtml('#0F111A')
    Panel    = [System.Drawing.ColorTranslator]::FromHtml('#171926')
    Panel2   = [System.Drawing.ColorTranslator]::FromHtml('#1F2233')
    Accent   = [System.Drawing.ColorTranslator]::FromHtml('#8B5CF6')
    Hover    = [System.Drawing.ColorTranslator]::FromHtml('#7C3AED')
    Active   = [System.Drawing.ColorTranslator]::FromHtml('#6D28D9')
    Text     = [System.Drawing.ColorTranslator]::FromHtml('#F8FAFC')
    Subtext  = [System.Drawing.ColorTranslator]::FromHtml('#94A3B8')
    Border   = [System.Drawing.ColorTranslator]::FromHtml('#2D324D')
    Success  = [System.Drawing.ColorTranslator]::FromHtml('#10B981')
    Danger   = [System.Drawing.ColorTranslator]::FromHtml('#EF4444')
    Warn     = [System.Drawing.ColorTranslator]::FromHtml('#F59E0B')
    Info     = [System.Drawing.ColorTranslator]::FromHtml('#38BDF8')
}

$script:AppDataDir      = Join-Path $env:LOCALAPPDATA 'DNSManagerPro'
$script:BackupFile      = Join-Path $script:AppDataDir 'backup.json'
$script:LogFile         = Join-Path $script:AppDataDir 'activity.log'
$script:Adapters        = @()
$script:SelectedAdapter = $null

$script:Presets = @(
    @{ Name = 'Automatic (DHCP)';           Note = 'Restore ISP / Router default DNS (DHCP)'; Mode = 'Automatic'; IPv4 = @();                                   IPv6 = @() },
    @{ Name = 'Cloudflare';                 Note = 'Lowest latency, high privacy (1.1.1.1)';  Mode = 'Manual';    IPv4 = @('1.1.1.1', '1.0.0.1');               IPv6 = @('2606:4700:4700::1111', '2606:4700:4700::1001') },
    @{ Name = 'Google Public DNS';          Note = 'Fast global anycast resolver (8.8.8.8)';  Mode = 'Manual';    IPv4 = @('8.8.8.8', '8.8.4.4');               IPv6 = @('2001:4860:4860::8888', '2001:4860:4860::8844') },
    @{ Name = 'Control D';                  Note = 'Smart routing, ultra fast resolver';      Mode = 'Manual';    IPv4 = @('76.76.2.0', '76.76.10.0');           IPv6 = @('2606:1a40::', '2606:1a40:1::') },
    @{ Name = 'AdGuard DNS';                Note = 'Blocks ads, banners and trackers';        Mode = 'Manual';    IPv4 = @('94.140.14.14', '94.140.15.15');      IPv6 = @('2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff') },
    @{ Name = 'Quad9 Security';             Note = 'Blocks malware, phishing and threats';    Mode = 'Manual';    IPv4 = @('9.9.9.9', '149.112.112.112');        IPv6 = @('2620:fe::fe', '2620:fe::9') },
    @{ Name = 'Cloudflare Security';        Note = 'Malware and malicious domain blocking';   Mode = 'Manual';    IPv4 = @('1.1.1.2', '1.0.0.2');               IPv6 = @('2606:4700:4700::1112', '2606:4700:4700::1002') },
    @{ Name = 'Cloudflare Family';          Note = 'Blocks malware and adult content';        Mode = 'Manual';    IPv4 = @('1.1.1.3', '1.0.0.3');               IPv6 = @('2606:4700:4700::1113', '2606:4700:4700::1003') },
    @{ Name = 'OpenDNS Home';               Note = 'High reliability by Cisco Systems';       Mode = 'Manual';    IPv4 = @('208.67.222.222', '208.67.220.220'); IPv6 = @('2620:119:35::35', '2620:119:53::53') },
    @{ Name = 'NextDNS';                    Note = 'Next-gen low-latency privacy resolver';   Mode = 'Manual';    IPv4 = @('45.90.28.0', '45.90.30.0');          IPv6 = @('2a07:a8c0::', '2a07:a8c1::') },
    @{ Name = 'VNPT DNS (Vietnam)';         Note = 'VNPT Telecom Vietnam internal routing';   Mode = 'Manual';    IPv4 = @('203.162.4.190', '203.162.4.191');   IPv6 = @() },
    @{ Name = 'Viettel DNS (Vietnam)';      Note = 'Viettel Telecom Vietnam direct routing';  Mode = 'Manual';    IPv4 = @('203.113.131.1', '203.113.131.2');   IPv6 = @() },
    @{ Name = 'FPT Telecom (Vietnam)';      Note = 'FPT Telecom Vietnam direct routing';      Mode = 'Manual';    IPv4 = @('210.245.24.20', '210.245.24.22');   IPv6 = @() },
    @{ Name = 'DNS.WATCH';                  Note = 'Fast, uncensored, no-logging resolver';   Mode = 'Manual';    IPv4 = @('84.200.69.80', '84.200.70.40');      IPv6 = @('2001:1608:10:25::1c04:b12f', '2001:1608:10:25::9249:d69b') }
)

function Ensure-Folder {
    if (-not (Test-Path $script:AppDataDir)) { New-Item -ItemType Directory $script:AppDataDir -Force | Out-Null }
}

function Write-Log {
    param([string]$Msg, [string]$Level = 'INFO')
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'HH:mm:ss'), $Level, $Msg
    try { Ensure-Folder; Add-Content $script:LogFile $line -Encoding UTF8 } catch {}
    if ($script:TxtLog -and -not $script:TxtLog.IsDisposed) {
        $color = switch ($Level) {
            'ERROR'   { $script:Theme.Danger }
            'WARN'    { $script:Theme.Warn }
            'SUCCESS' { $script:Theme.Success }
            'INFO'    { $script:Theme.Info }
            default   { $script:Theme.Subtext }
        }
        $script:TxtLog.SelectionStart = $script:TxtLog.TextLength
        $script:TxtLog.SelectionLength = 0
        $script:TxtLog.SelectionColor = $color
        $script:TxtLog.AppendText("$line`r`n")
        $script:TxtLog.ScrollToCaret()
    }
}

function ConvertTo-DnsQueryName {
    param([string]$Domain)
    $bytes = New-Object System.Collections.Generic.List[byte]
    foreach ($label in $Domain.TrimEnd('.').Split('.')) {
        $labelBytes = [System.Text.Encoding]::ASCII.GetBytes($label)
        if ($labelBytes.Length -gt 63) { throw 'DNS label is too long.' }
        $bytes.Add([byte]$labelBytes.Length)
        foreach ($b in $labelBytes) { $bytes.Add($b) }
    }
    $bytes.Add(0)
    return $bytes.ToArray()
}

function New-DnsQueryPacket {
    param([string]$Domain, [UInt16]$TransactionId)
    $packet = New-Object System.Collections.Generic.List[byte]
    $packet.Add([byte](($TransactionId -shr 8) -band 0xFF))
    $packet.Add([byte]($TransactionId -band 0xFF))
    $packet.Add(0x01); $packet.Add(0x00)
    $packet.Add(0x00); $packet.Add(0x01)
    $packet.Add(0x00); $packet.Add(0x00)
    $packet.Add(0x00); $packet.Add(0x00)
    $packet.Add(0x00); $packet.Add(0x00)
    $qname = ConvertTo-DnsQueryName -Domain $Domain
    foreach ($b in $qname) { $packet.Add($b) }
    $packet.Add(0x00); $packet.Add(0x01)
    $packet.Add(0x00); $packet.Add(0x01)
    return $packet.ToArray()
}

function Get-DnsQueryMs {
    param(
        [string]$Server,
        [string]$Domain = 'www.cloudflare.com',
        [int]$TimeoutMs = 1200
    )
    if ([string]::IsNullOrWhiteSpace($Server)) { return -1 }
    
    $ipAddr = $null
    if (-not [System.Net.IPAddress]::TryParse($Server, [ref]$ipAddr)) { return -1 }

    $udp = $null
    try {
        $udp = New-Object System.Net.Sockets.UdpClient($ipAddr.AddressFamily)
        $udp.Client.ReceiveTimeout = $TimeoutMs
        $udp.Client.SendTimeout = $TimeoutMs
        $udp.Connect($ipAddr, 53)
        
        $transactionId = [UInt16](Get-Random -Minimum 1 -Maximum 65535)
        $query = New-DnsQueryPacket -Domain $Domain -TransactionId $transactionId
        $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        if ($ipAddr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
            $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::IPv6Any, 0)
        }
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        [void]$udp.Send($query, $query.Length)
        $response = $udp.Receive([ref]$remote)
        $sw.Stop()
        
        if ($response.Length -lt 12) { return -1 }
        $responseId = ([int]$response[0] -shl 8) -bor [int]$response[1]
        if ($responseId -ne $transactionId) { return -1 }
        $rcode = $response[3] -band 0x0F
        if ($rcode -ne 0) { return -1 }
        $answerCount = ([int]$response[6] -shl 8) -bor [int]$response[7]
        if ($answerCount -lt 1) { return -1 }
        
        return [int][Math]::Max(1, [Math]::Round($sw.Elapsed.TotalMilliseconds))
    } catch {
        return -1
    } finally {
        if ($udp) {
            $udp.Close()
            $udp.Dispose()
        }
    }
}

function Test-ValidIP {
    param([string]$IP, [string]$Family = 'IPv4')
    if ([string]::IsNullOrWhiteSpace($IP)) { return $false }
    try {
        $ipObj = [System.Net.IPAddress]::Parse($IP.Trim())
        if ($Family -eq 'IPv4') {
            return ($ipObj.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork)
        } else {
            return ($ipObj.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6)
        }
    } catch {
        return $false
    }
}

function Get-ActiveAdapters {
    $all = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Disabled' -and $_.Status -ne 'Not Present' })
    return @($all | Sort-Object @{ Expression = { if ($_.HardwareInterface -and $_.Status -eq 'Up') { 0 } elseif ($_.Status -eq 'Up') { 1 } else { 2 } } }, InterfaceMetric)
}

function Get-AdapterDNS {
    param([int]$ifIndex)
    $res = @{ IPv4 = @(); IPv6 = @() }
    try {
        $addrs = Get-DnsClientServerAddress -InterfaceIndex $ifIndex -ErrorAction Stop
        $v4 = ($addrs | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses
        if ($v4) { $res.IPv4 = @([string[]]$v4) }
        $v6 = ($addrs | Where-Object { $_.AddressFamily -eq 23 }).ServerAddresses
        if ($v6) { $res.IPv6 = @([string[]]$v6) }
    } catch {}
    return $res
}

function Set-DNSConfig {
    param(
        [int]$ifIndex,
        [hashtable]$Preset,
        [bool]$ApplyIPv6 = $true,
        [string]$AdapterAlias = ""
    )
    if ($Preset.Mode -eq 'Automatic') {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ResetServerAddresses -ErrorAction Stop
        } catch {
            if ($AdapterAlias) {
                netsh interface ipv4 set dnsservers name="$AdapterAlias" source=dhcp 2>$null
                netsh interface ipv6 set dnsservers name="$AdapterAlias" source=dhcp 2>$null
            } else {
                throw $_
            }
        }
    } else {
        $allServers = New-Object System.Collections.Generic.List[string]
        $v4List = New-Object System.Collections.Generic.List[string]

        if ($Preset.IPv4) {
            foreach ($ip in $Preset.IPv4) {
                $strIp = [string]$ip
                if (-not [string]::IsNullOrWhiteSpace($strIp) -and (Test-ValidIP -IP $strIp -Family 'IPv4')) {
                    $v4List.Add($strIp.Trim())
                    $allServers.Add($strIp.Trim())
                }
            }
        }

        if ($ApplyIPv6 -and $Preset.IPv6) {
            foreach ($ip in $Preset.IPv6) {
                $strIp = [string]$ip
                if (-not [string]::IsNullOrWhiteSpace($strIp) -and (Test-ValidIP -IP $strIp -Family 'IPv6')) {
                    $allServers.Add($strIp.Trim())
                }
            }
        }

        if ($allServers.Count -eq 0) {
            throw 'No valid DNS server addresses specified.'
        }

        [string[]]$serverArray = $allServers.ToArray()
        try {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $serverArray -ErrorAction Stop
        } catch {
            if ($v4List.Count -gt 0) {
                try {
                    [string[]]$v4Arr = $v4List.ToArray()
                    Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $v4Arr -ErrorAction Stop
                } catch {
                    if ($AdapterAlias) {
                        netsh interface ipv4 set dnsservers name="$AdapterAlias" static "$($v4List[0])" primary 2>$null
                        if ($v4List.Count -gt 1) {
                            netsh interface ipv4 add dnsservers name="$AdapterAlias" "$($v4List[1])" index=2 2>$null
                        }
                    } else {
                        throw $_
                    }
                }
            } else {
                throw $_
            }
        }
    }
    try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch {}
}

function Backup-CurrentDNS {
    param([int]$ifIndex, [string]$Alias)
    $curr = Get-AdapterDNS -ifIndex $ifIndex
    $mode = if ($curr.IPv4.Count -eq 0 -and $curr.IPv6.Count -eq 0) { 'Automatic' } else { 'Manual' }
    $data = [PSCustomObject]@{
        Time    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Adapter = $Alias
        ifIndex = $ifIndex
        Mode    = $mode
        IPv4    = @($curr.IPv4)
        IPv6    = @($curr.IPv6)
    }
    Ensure-Folder
    $json = $data | ConvertTo-Json -Compress
    Set-Content $script:BackupFile -Value $json -Encoding UTF8
}

function Set-RoundRegion {
    param($Control, [int]$Radius = 4)
    try {
        $w = $Control.Width
        $h = $Control.Height
        if ($w -lt 4 -or $h -lt 4) { return }
        $r = [Math]::Max(2, [Math]::Min($Radius, [Math]::Floor([Math]::Min($w, $h) / 2)))
        $d = $r * 2
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($w - $d, 0, $d, $d, 270, 90)
        $path.AddArc($w - $d, $h - $d, $d, $d, 0, 90)
        $path.AddArc(0, $h - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        $Control.Region = New-Object System.Drawing.Region($path)
        $path.Dispose()
    } catch {}
}

function New-SectionPanel {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($X, $Y)
    $p.Size = New-Object System.Drawing.Size($W, $H)
    $p.BackColor = $script:Theme.Panel
    $p.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen($script:Theme.Border, 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width - 1, $s.Height - 1)
        $pen.Dispose()
    })
    return $p
}

function New-CustomButton {
    param(
        [string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H,
        [System.Drawing.Color]$BgColor,
        [ScriptBlock]$OnClick,
        [switch]$Emphasis
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($W, $H)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $BgColor
    $btn.ForeColor = $script:Theme.Text
    $weight = if ($Emphasis) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $btn.Font = New-Object System.Drawing.Font('Segoe UI', 9, $weight)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.UseVisualStyleBackColor = $false
    $hoverColor = [System.Drawing.Color]::FromArgb(255,
        [Math]::Min(255, $BgColor.R + 22),
        [Math]::Min(255, $BgColor.G + 22),
        [Math]::Min(255, $BgColor.B + 22))
    if ($Emphasis) { $hoverColor = $script:Theme.Hover }
    $btn.Tag = @{ Normal = $BgColor; Hover = $hoverColor }
    $btn.Add_MouseEnter({ $this.BackColor = $this.Tag.Hover })
    $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.Normal })
    if ($OnClick) { $btn.Add_Click($OnClick) }
    Set-RoundRegion -Control $btn -Radius 4
    return $btn
}

function Build-UI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DNS Manager Pro - Fast & Smart DNS Changer'
    $form.ClientSize = New-Object System.Drawing.Size(880, 680)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.BackColor = $script:Theme.BG
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $pHeader = New-Object System.Windows.Forms.Panel
    $pHeader.Size = New-Object System.Drawing.Size(880, 60)
    $pHeader.Location = New-Object System.Drawing.Point(0, 0)
    $pHeader.BackColor = $script:Theme.Panel
    $pHeader.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen($script:Theme.Border, 1)
        $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
        $pen.Dispose()
    })
    $form.Controls.Add($pHeader)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = 'DNS Manager Pro'
    $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $script:Theme.Text
    $lblTitle.Location = New-Object System.Drawing.Point(20, 10)
    $lblTitle.AutoSize = $true
    $pHeader.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = 'Fast, intelligent DNS benchmark and optimizer'
    $lblSub.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $lblSub.ForeColor = $script:Theme.Subtext
    $lblSub.Location = New-Object System.Drawing.Point(24, 35)
    $lblSub.AutoSize = $true
    $pHeader.Controls.Add($lblSub)

    # IPv6 Toggle on Header
    $script:ChkIPv6 = New-Object System.Windows.Forms.CheckBox
    $script:ChkIPv6.Text = 'Include IPv6 DNS'
    $script:ChkIPv6.Checked = $true
    $script:ChkIPv6.ForeColor = $script:Theme.Subtext
    $script:ChkIPv6.Location = New-Object System.Drawing.Point(740, 20)
    $script:ChkIPv6.AutoSize = $true
    $script:ChkIPv6.Cursor = [System.Windows.Forms.Cursors]::Hand
    $pHeader.Controls.Add($script:ChkIPv6)

    # Adapter Section
    $pAdapter = New-SectionPanel -X 20 -Y 72 -W 840 -H 75
    $form.Controls.Add($pAdapter)

    $lblCard = New-Object System.Windows.Forms.Label
    $lblCard.Text = 'Network Adapter:'
    $lblCard.ForeColor = $script:Theme.Subtext
    $lblCard.Location = New-Object System.Drawing.Point(15, 12)
    $lblCard.AutoSize = $true
    $pAdapter.Controls.Add($lblCard)

    $script:CboAdapter = New-Object System.Windows.Forms.ComboBox
    $script:CboAdapter.Location = New-Object System.Drawing.Point(15, 34)
    $script:CboAdapter.Size = New-Object System.Drawing.Size(550, 25)
    $script:CboAdapter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $script:CboAdapter.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $script:CboAdapter.BackColor = $script:Theme.Panel2
    $script:CboAdapter.ForeColor = $script:Theme.Text
    $pAdapter.Controls.Add($script:CboAdapter)

    $btnRefresh = New-CustomButton -Text 'Refresh' -X 580 -Y 33 -W 115 -H 27 -BgColor $script:Theme.Panel2 -OnClick { Reload-AdapterList }
    $pAdapter.Controls.Add($btnRefresh)

    $btnFlush = New-CustomButton -Text 'Flush DNS' -X 705 -Y 33 -W 120 -H 27 -BgColor $script:Theme.Panel2 -OnClick {
        try {
            Clear-DnsClientCache
            Write-Log 'DNS Cache cleared successfully.' 'SUCCESS'
        } catch {
            Write-Log 'Failed to flush DNS cache.' 'ERROR'
        }
    }
    $pAdapter.Controls.Add($btnFlush)

    $script:LblCurrentDNS = New-Object System.Windows.Forms.Label
    $script:LblCurrentDNS.Text = 'Current DNS: --'
    $script:LblCurrentDNS.ForeColor = $script:Theme.Info
    $script:LblCurrentDNS.Location = New-Object System.Drawing.Point(180, 12)
    $script:LblCurrentDNS.AutoSize = $true
    $pAdapter.Controls.Add($script:LblCurrentDNS)

    # Preset List Section
    $pGrid = New-SectionPanel -X 20 -Y 159 -W 840 -H 250
    $form.Controls.Add($pGrid)

    $script:LV = New-Object System.Windows.Forms.ListView
    $script:LV.Size = New-Object System.Drawing.Size(810, 190)
    $script:LV.Location = New-Object System.Drawing.Point(15, 12)
    $script:LV.View = [System.Windows.Forms.View]::Details
    $script:LV.FullRowSelect = $true
    $script:LV.MultiSelect = $false
    $script:LV.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $script:LV.BackColor = $script:Theme.Panel2
    $script:LV.ForeColor = $script:Theme.Text
    $script:LV.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable

    [void]$script:LV.Columns.Add('Provider', 165)
    [void]$script:LV.Columns.Add('Primary DNS', 125)
    [void]$script:LV.Columns.Add('Secondary DNS', 125)
    [void]$script:LV.Columns.Add('Description / Features', 300)
    [void]$script:LV.Columns.Add('DNS Query', 90)
    $pGrid.Controls.Add($script:LV)
    try { [void][DnsMgr.Win32Con]::SetWindowTheme($script:LV.Handle, 'Explorer', $null) } catch {}

    $script:LV.Add_DoubleClick({
        Apply-SelectedPreset
    })

    $btnApply = New-CustomButton -Text 'Apply Selected' -X 15 -Y 210 -W 190 -H 28 -BgColor $script:Theme.Accent -OnClick { Apply-SelectedPreset } -Emphasis
    $pGrid.Controls.Add($btnApply)

    $btnPing = New-CustomButton -Text 'Benchmark DNS Speed' -X 215 -Y 210 -W 190 -H 28 -BgColor $script:Theme.Panel2 -OnClick { Test-DNSSpeed }
    $pGrid.Controls.Add($btnPing)

    $btnFastest = New-CustomButton -Text 'Auto Best DNS' -X 415 -Y 210 -W 220 -H 28 -BgColor $script:Theme.Success -OnClick { Select-FastestDNS } -Emphasis
    $pGrid.Controls.Add($btnFastest)

    $btnBackup = New-CustomButton -Text 'Restore Backup' -X 645 -Y 210 -W 180 -H 28 -BgColor $script:Theme.Panel2 -OnClick { Restore-DNSBackup }
    $pGrid.Controls.Add($btnBackup)

    # Custom DNS Section
    $pCustom = New-SectionPanel -X 20 -Y 420 -W 840 -H 65
    $form.Controls.Add($pCustom)

    $lblP4 = New-Object System.Windows.Forms.Label
    $lblP4.Text = 'Primary IPv4:'
    $lblP4.ForeColor = $script:Theme.Subtext
    $lblP4.Location = New-Object System.Drawing.Point(15, 22)
    $lblP4.AutoSize = $true
    $pCustom.Controls.Add($lblP4)

    $script:TxtIPv4A = New-Object System.Windows.Forms.TextBox
    $script:TxtIPv4A.Location = New-Object System.Drawing.Point(100, 19)
    $script:TxtIPv4A.Size = New-Object System.Drawing.Size(155, 23)
    $script:TxtIPv4A.BackColor = $script:Theme.Panel2
    $script:TxtIPv4A.ForeColor = $script:Theme.Text
    $script:TxtIPv4A.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pCustom.Controls.Add($script:TxtIPv4A)

    $lblS4 = New-Object System.Windows.Forms.Label
    $lblS4.Text = 'Secondary IPv4:'
    $lblS4.ForeColor = $script:Theme.Subtext
    $lblS4.Location = New-Object System.Drawing.Point(270, 22)
    $lblS4.AutoSize = $true
    $pCustom.Controls.Add($lblS4)

    $script:TxtIPv4B = New-Object System.Windows.Forms.TextBox
    $script:TxtIPv4B.Location = New-Object System.Drawing.Point(370, 19)
    $script:TxtIPv4B.Size = New-Object System.Drawing.Size(155, 23)
    $script:TxtIPv4B.BackColor = $script:Theme.Panel2
    $script:TxtIPv4B.ForeColor = $script:Theme.Text
    $script:TxtIPv4B.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pCustom.Controls.Add($script:TxtIPv4B)

    $btnApplyCustom = New-CustomButton -Text 'Apply Custom DNS' -X 645 -Y 17 -W 180 -H 27 -BgColor $script:Theme.Accent -OnClick { Apply-CustomDNS } -Emphasis
    $pCustom.Controls.Add($btnApplyCustom)

    # Log Section
    $pLog = New-SectionPanel -X 20 -Y 496 -W 840 -H 140
    $form.Controls.Add($pLog)

    $script:TxtLog = New-Object System.Windows.Forms.RichTextBox
    $script:TxtLog.Size = New-Object System.Drawing.Size(810, 115)
    $script:TxtLog.Location = New-Object System.Drawing.Point(15, 12)
    $script:TxtLog.BackColor = $script:Theme.Panel2
    $script:TxtLog.ForeColor = $script:Theme.Text
    $script:TxtLog.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $script:TxtLog.ReadOnly = $true
    $script:TxtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
    $pLog.Controls.Add($script:TxtLog)

    # Footer
    $pFooter = New-Object System.Windows.Forms.Panel
    $pFooter.Size = New-Object System.Drawing.Size(880, 30)
    $pFooter.Location = New-Object System.Drawing.Point(0, 650)
    $pFooter.BackColor = $script:Theme.Panel
    $pFooter.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen($script:Theme.Border, 1)
        $e.Graphics.DrawLine($pen, 0, 0, $s.Width, 0)
        $pen.Dispose()
    })
    $form.Controls.Add($pFooter)

    $lblFooterLeft = New-Object System.Windows.Forms.Label
    $lblFooterLeft.Text = 'Tip: Double-click any DNS row to apply immediately.'
    $lblFooterLeft.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $lblFooterLeft.ForeColor = $script:Theme.Subtext
    $lblFooterLeft.Location = New-Object System.Drawing.Point(20, 6)
    $lblFooterLeft.AutoSize = $true
    $pFooter.Controls.Add($lblFooterLeft)

    $lblFooterRight = New-Object System.Windows.Forms.Label
    $lblFooterRight.Text = 'DNS Manager Pro - Credit: TQN'
    $lblFooterRight.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $lblFooterRight.ForeColor = $script:Theme.Subtext
    $lblFooterRight.AutoSize = $true
    $lblFooterRight.Location = New-Object System.Drawing.Point(680, 6)
    $pFooter.Controls.Add($lblFooterRight)

    $script:CboAdapter.Add_SelectedIndexChanged({
        if ($script:CboAdapter.SelectedIndex -ge 0 -and $script:CboAdapter.SelectedIndex -lt $script:Adapters.Count) {
            $script:SelectedAdapter = $script:Adapters[$script:CboAdapter.SelectedIndex]
            Update-DNSDisplay
        }
    })

    return $form
}

function Reload-AdapterList {
    $script:CboAdapter.Items.Clear()
    $script:Adapters = Get-ActiveAdapters
    if ($script:Adapters.Count -eq 0) {
        Write-Log 'No network adapters found.' 'ERROR'
        return
    }
    foreach ($a in $script:Adapters) {
        $status = if ($a.Status -eq 'Up') { 'Connected' } else { [string]$a.Status }
        $type = if ($a.HardwareInterface) { 'Hardware' } else { 'Virtual/VPN' }
        [void]$script:CboAdapter.Items.Add(("{0}  [{1} - {2}]" -f $a.Name, $status, $type))
    }
    $script:CboAdapter.SelectedIndex = 0
    Write-Log ('Network adapters reloaded (found {0} adapters).' -f $script:Adapters.Count) 'INFO'
}

function Update-DNSDisplay {
    if (-not $script:SelectedAdapter) { return }
    $info = Get-AdapterDNS -ifIndex $script:SelectedAdapter.InterfaceIndex
    $v4 = if ($info.IPv4.Count -gt 0) { $info.IPv4 -join ', ' } else { 'DHCP (Automatic)' }
    $script:LblCurrentDNS.Text = "Current DNS: $v4"
}

function Populate-Presets {
    $script:LV.Items.Clear()
    foreach ($p in $script:Presets) {
        $p1 = if ($p.IPv4.Count -gt 0) { $p.IPv4[0] } else { 'Auto' }
        $p2 = if ($p.IPv4.Count -gt 1) { $p.IPv4[1] } else { '--' }
        $item = New-Object System.Windows.Forms.ListViewItem($p.Name)
        [void]$item.SubItems.Add($p1)
        [void]$item.SubItems.Add($p2)
        [void]$item.SubItems.Add([string]$p.Note)
        [void]$item.SubItems.Add('--')
        $item.Tag = $p
        [void]$script:LV.Items.Add($item)
    }
    if ($script:LV.Items.Count -gt 0) { $script:LV.Items[0].Selected = $true }
}

function Apply-PresetDirect {
    param([hashtable]$Preset)
    if (-not $Preset -or -not $script:SelectedAdapter) {
        Write-Log 'No network adapter or preset selected.' 'WARN'
        return
    }
    $applyV6 = if ($script:ChkIPv6) { $script:ChkIPv6.Checked } else { $true }
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        Backup-CurrentDNS -ifIndex $script:SelectedAdapter.InterfaceIndex -Alias $script:SelectedAdapter.Name
        Set-DNSConfig -ifIndex $script:SelectedAdapter.InterfaceIndex -Preset $Preset -ApplyIPv6 $applyV6 -AdapterAlias $script:SelectedAdapter.Name
        Update-DNSDisplay
        Write-Log ("Applied '{0}' to {1}" -f $Preset.Name, $script:SelectedAdapter.Name) 'SUCCESS'
    } catch {
        Write-Log ("Error applying DNS: {0}" -f $_.Exception.Message) 'ERROR'
    } finally {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
    }
}

function Apply-SelectedPreset {
    if ($script:LV.SelectedItems.Count -eq 0) {
        Write-Log 'No preset selected in table.' 'WARN'
        return
    }
    $preset = $script:LV.SelectedItems[0].Tag
    Apply-PresetDirect -Preset $preset
}

function Apply-CustomDNS {
    if (-not $script:SelectedAdapter) {
        Write-Log 'No adapter selected.' 'WARN'
        return
    }
    $ip1 = $script:TxtIPv4A.Text.Trim()
    $ip2 = $script:TxtIPv4B.Text.Trim()
    if (-not (Test-ValidIP -IP $ip1 -Family 'IPv4')) {
        Write-Log 'Invalid Primary IPv4 address (e.g. 1.1.1.1).' 'WARN'
        return
    }
    $v4 = @($ip1)
    if ($ip2 -and (Test-ValidIP -IP $ip2 -Family 'IPv4')) { $v4 += $ip2 }
    $preset = @{ Name = 'Custom'; Mode = 'Manual'; IPv4 = $v4; IPv6 = @() }
    Apply-PresetDirect -Preset $preset
}

function Test-DNSSpeed {
    $queryDomain = 'www.cloudflare.com'
    Write-Log ("Benchmarking DNS query speeds against {0}..." -f $queryDomain) 'INFO'
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        foreach ($item in $script:LV.Items) {
            $preset = $item.Tag
            if ($preset.Mode -eq 'Automatic') {
                $item.SubItems[4].Text = 'N/A'
                continue
            }
            $target = $preset.IPv4[0]
            $ms1 = Get-DnsQueryMs -Server $target -Domain $queryDomain -TimeoutMs 1000
            $ms2 = Get-DnsQueryMs -Server $target -Domain $queryDomain -TimeoutMs 1000
            
            $ms = -1
            if ($ms1 -ge 0 -and $ms2 -ge 0) {
                $ms = [Math]::Min($ms1, $ms2)
            } elseif ($ms1 -ge 0) {
                $ms = $ms1
            } elseif ($ms2 -ge 0) {
                $ms = $ms2
            }

            if ($ms -ge 0) {
                $item.SubItems[4].Text = "$ms ms"
            } else {
                $item.SubItems[4].Text = 'Timeout'
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
        Write-Log 'DNS query benchmark completed.' 'SUCCESS'
    } finally {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
    }
}

function Select-FastestDNS {
    Test-DNSSpeed
    $bestItem = $null
    $minQueryMs = [int]::MaxValue
    foreach ($item in $script:LV.Items) {
        if ($item.SubItems[4].Text -match '^(\d+) ms$') {
            $queryMs = [int]$Matches[1]
            if ($queryMs -lt $minQueryMs) {
                $minQueryMs = $queryMs
                $bestItem = $item
            }
        }
    }
    if ($bestItem -and $bestItem.Tag) {
        foreach ($it in $script:LV.Items) { $it.Selected = $false }
        $bestItem.Selected = $true
        $bestItem.Focused = $true
        $script:LV.EnsureVisible($bestItem.Index)
        Apply-PresetDirect -Preset $bestItem.Tag
        Write-Log ("Auto-selected fastest DNS query server: {0} ({1} ms)" -f $bestItem.Tag.Name, $minQueryMs) 'SUCCESS'
    } else {
        Write-Log 'Could not find responding DNS server.' 'WARN'
    }
}

function Restore-DNSBackup {
    if (-not (Test-Path $script:BackupFile) -or -not $script:SelectedAdapter) {
        Write-Log 'No previous DNS backup found.' 'WARN'
        return
    }
    try {
        $raw = Get-Content $script:BackupFile -Raw -Encoding UTF8
        $backup = ConvertFrom-Json -InputObject $raw
        $preset = @{
            Name = 'Previous Backup'
            Mode = $backup.Mode
            IPv4 = @($backup.IPv4)
            IPv6 = @($backup.IPv6)
        }
        $applyV6 = ($backup.IPv6 -and @($backup.IPv6).Count -gt 0)
        Set-DNSConfig -ifIndex $script:SelectedAdapter.InterfaceIndex -Preset $preset -ApplyIPv6 $applyV6 -AdapterAlias $script:SelectedAdapter.Name
        Update-DNSDisplay
        Write-Log ("Restored DNS backup from {0}" -f $backup.Time) 'SUCCESS'
    } catch {
        Write-Log ("Error restoring DNS backup: {0}" -f $_.Exception.Message) 'ERROR'
    }
}

try {
    Ensure-Folder
    $mainForm = Build-UI
    Reload-AdapterList
    Populate-Presets
    Write-Log 'DNS Manager Pro started successfully.' 'INFO'
    [System.Windows.Forms.Application]::Run($mainForm)
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}