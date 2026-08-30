#Requires -Version 5.1
<#
    DNS Manager Pro
    Developed by TQN
#>

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# --- Hide Console Window ---
$win32Sig = @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   public static extern bool  ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("uxtheme.dll", CharSet = CharSet.Unicode)] public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
'@
try {
    $type = Add-Type -MemberDefinition $win32Sig -Name 'Win32Con' -Namespace 'DnsMgr' -PassThru
    $ch = $type::GetConsoleWindow()
    if ($ch -ne [IntPtr]::Zero) { [void]$type::ShowWindow($ch, 0) }
} catch {}

# --- Admin Check & Auto Elevation ---
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    try {
        Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$PSCommandPath`"") -Verb RunAs
    } catch {}
    exit
}

# --- Theme Configuration ---
$script:Theme = @{
    BG       = [System.Drawing.ColorTranslator]::FromHtml('#0D0B14')
    Panel    = [System.Drawing.ColorTranslator]::FromHtml('#16121F')
    Panel2   = [System.Drawing.ColorTranslator]::FromHtml('#1E1829')
    Accent   = [System.Drawing.ColorTranslator]::FromHtml('#A855F7')
    Hover    = [System.Drawing.ColorTranslator]::FromHtml('#9333EA')
    Text     = [System.Drawing.ColorTranslator]::FromHtml('#F5F3FF')
    Subtext  = [System.Drawing.ColorTranslator]::FromHtml('#A1A1AA')
    Border   = [System.Drawing.ColorTranslator]::FromHtml('#2A2335')
    Success  = [System.Drawing.ColorTranslator]::FromHtml('#3FB950')
    Danger   = [System.Drawing.ColorTranslator]::FromHtml('#F85149')
    Warn     = [System.Drawing.ColorTranslator]::FromHtml('#D29922')
}

# --- Data & Paths ---
$script:AppDataDir      = Join-Path $env:LOCALAPPDATA 'DNSManagerPro'
$script:BackupFile      = Join-Path $script:AppDataDir 'backup.json'
$script:LogFile         = Join-Path $script:AppDataDir 'activity.log'
$script:Adapters        = @()
$script:SelectedAdapter = $null

$script:Presets = @(
    @{ Name = 'Automatic (DHCP)';           Note = 'Restore default DNS from router / ISP';   Mode = 'Automatic'; IPv4 = @();                                   IPv6 = @() },
    @{ Name = 'Google DNS';                 Note = 'Fast global anycast network';             Mode = 'Manual';    IPv4 = @('8.8.8.8', '8.8.4.4');               IPv6 = @('2001:4860:4860::8888', '2001:4860:4860::8844') },
    @{ Name = 'Cloudflare';                 Note = 'Lowest ping, strong privacy focus';       Mode = 'Manual';    IPv4 = @('1.1.1.1', '1.0.0.1');               IPv6 = @('2606:4700:4700::1111', '2606:4700:4700::1001') },
    @{ Name = 'Cloudflare Security';        Note = 'Blocks malware and phishing domains';     Mode = 'Manual';    IPv4 = @('1.1.1.2', '1.0.0.2');               IPv6 = @('2606:4700:4700::1112', '2606:4700:4700::1002') },
    @{ Name = 'Quad9 Security';             Note = 'High-security resolver, blocks malware';  Mode = 'Manual';    IPv4 = @('9.9.9.9', '149.112.112.112');        IPv6 = @('2620:fe::fe', '2620:fe::9') },
    @{ Name = 'OpenDNS Home';               Note = 'Stable resolver with basic filtering';    Mode = 'Manual';    IPv4 = @('208.67.222.222', '208.67.220.220'); IPv6 = @('2620:119:35::35', '2620:119:53::53') },
    @{ Name = 'AdGuard DNS';                Note = 'Blocks ads, popups and trackers';         Mode = 'Manual';    IPv4 = @('94.140.14.14', '94.140.15.15');      IPv6 = @('2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff') },
    @{ Name = 'Control D';                  Note = 'Configurable resolver, fast routing';     Mode = 'Manual';    IPv4 = @('76.76.2.0', '76.76.10.0');           IPv6 = @('2606:1a40::', '2606:1a40:1::') }
)

# --- Helper Functions ---
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
        $bytes.AddRange([byte[]]$labelBytes)
    }
    $bytes.Add(0)
    return $bytes.ToArray()
}

function New-DnsQueryPacket {
    param([string]$Domain, [UInt16]$TransactionId)

    $packet = New-Object System.Collections.Generic.List[byte]
    $packet.Add([byte](($TransactionId -shr 8) -band 0xFF))
    $packet.Add([byte]($TransactionId -band 0xFF))
    $packet.AddRange([byte[]](0x01, 0x00)) # Standard recursive query
    $packet.AddRange([byte[]](0x00, 0x01)) # One question
    $packet.AddRange([byte[]](0x00, 0x00)) # Answer RRs
    $packet.AddRange([byte[]](0x00, 0x00)) # Authority RRs
    $packet.AddRange([byte[]](0x00, 0x00)) # Additional RRs
    $packet.AddRange([byte[]](ConvertTo-DnsQueryName -Domain $Domain))
    $packet.AddRange([byte[]](0x00, 0x01)) # Type A
    $packet.AddRange([byte[]](0x00, 0x01)) # Class IN
    return $packet.ToArray()
}

function Get-DnsQueryMs {
    param(
        [string]$Server,
        [string]$Domain = 'www.cloudflare.com',
        [int]$TimeoutMs = 1200
    )

    $udp = New-Object System.Net.Sockets.UdpClient
    try {
        $udp.Client.ReceiveTimeout = $TimeoutMs
        $udp.Client.SendTimeout = $TimeoutMs
        $udp.Connect($Server, 53)

        $transactionId = [UInt16](Get-Random -Minimum 1 -Maximum 65535)
        $query = New-DnsQueryPacket -Domain $Domain -TransactionId $transactionId
        $remote = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
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
        $udp.Close()
        $udp.Dispose()
    }
}

function Test-ValidIP {
    param([string]$IP, [string]$Family = 'IPv4')
    $out = $null
    $type = if ($Family -eq 'IPv4') { [System.Net.Sockets.AddressFamily]::InterNetwork } else { [System.Net.Sockets.AddressFamily]::InterNetworkV6 }
    return ([System.Net.IPAddress]::TryParse($IP, [ref]$out) -and $out.AddressFamily -eq $type)
}

# --- Network Logic ---
function Get-ActiveAdapters {
    return @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.HardwareInterface } | Sort-Object @{ Expression = { if ($_.Status -eq 'Up') { 0 } else { 1 } } }, InterfaceMetric)
}

function Get-AdapterDNS {
    param([int]$ifIndex)
    $res = @{ IPv4 = @(); IPv6 = @() }
    try {
        $addrs = Get-DnsClientServerAddress -InterfaceIndex $ifIndex -ErrorAction Stop
        $res.IPv4 = @(($addrs | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses)
        $res.IPv6 = @(($addrs | Where-Object { $_.AddressFamily -eq 23 }).ServerAddresses)
    } catch {}
    return $res
}

function Set-DNSConfig {
    param([int]$ifIndex, [hashtable]$Preset, [bool]$ApplyIPv6 = $true)
    if ($Preset.Mode -eq 'Automatic') {
        Reset-DnsClientServerAddress -InterfaceIndex $ifIndex -Confirm:$false
    } else {
        $v4 = @($Preset.IPv4)
        if ($v4.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses $v4 -ErrorAction Stop
        }
        if ($ApplyIPv6 -and $Preset.ContainsKey('IPv6') -and (@($Preset.IPv6).Count -gt 0)) {
            try { Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @($Preset.IPv6) -ErrorAction SilentlyContinue } catch {}
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
        Mode    = $mode
        IPv4    = @($curr.IPv4)
        IPv6    = @($curr.IPv6)
    }
    Ensure-Folder
    $json = $data | ConvertTo-Json -Compress
    Set-Content $script:BackupFile -Value $json -Encoding UTF8
}

# --- UI Helpers ---
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
        [Math]::Min(255, $BgColor.R + 18),
        [Math]::Min(255, $BgColor.G + 18),
        [Math]::Min(255, $BgColor.B + 18))
    if ($Emphasis) { $hoverColor = $script:Theme.Hover }
    $btn.Tag = @{ Normal = $BgColor; Hover = $hoverColor }

    $btn.Add_MouseEnter({ $this.BackColor = $this.Tag.Hover })
    $btn.Add_MouseLeave({ $this.BackColor = $this.Tag.Normal })

    if ($OnClick) { $btn.Add_Click($OnClick) }
    Set-RoundRegion -Control $btn -Radius 4
    return $btn
}

# --- GUI Construction ---
function Build-UI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DNS Manager Pro'
    $form.ClientSize = New-Object System.Drawing.Size(860, 668)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.BackColor = $script:Theme.BG
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    # --- Header ---
    $pHeader = New-Object System.Windows.Forms.Panel
    $pHeader.Size = New-Object System.Drawing.Size(860, 60)
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
    $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $script:Theme.Text
    $lblTitle.Location = New-Object System.Drawing.Point(20, 10)
    $lblTitle.AutoSize = $true
    $pHeader.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = 'DNS Configuration & Optimization Utility'
    $lblSub.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $lblSub.ForeColor = $script:Theme.Subtext
    $lblSub.Location = New-Object System.Drawing.Point(22, 36)
    $lblSub.AutoSize = $true
    $pHeader.Controls.Add($lblSub)

    # --- Section 1: Adapter Selector ---
    $pAdapter = New-SectionPanel -X 20 -Y 72 -W 820 -H 75
    $form.Controls.Add($pAdapter)

    $lblCard = New-Object System.Windows.Forms.Label
    $lblCard.Text = 'Network Adapter'
    $lblCard.ForeColor = $script:Theme.Subtext
    $lblCard.Location = New-Object System.Drawing.Point(15, 12)
    $lblCard.AutoSize = $true
    $pAdapter.Controls.Add($lblCard)

    $script:CboAdapter = New-Object System.Windows.Forms.ComboBox
    $script:CboAdapter.Location = New-Object System.Drawing.Point(15, 34)
    $script:CboAdapter.Size = New-Object System.Drawing.Size(540, 25)
    $script:CboAdapter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $script:CboAdapter.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $script:CboAdapter.BackColor = $script:Theme.Panel2
    $script:CboAdapter.ForeColor = $script:Theme.Text
    $pAdapter.Controls.Add($script:CboAdapter)

    $btnRefresh = New-CustomButton -Text 'Refresh' -X 565 -Y 33 -W 110 -H 27 -BgColor $script:Theme.Panel2 -OnClick { Reload-AdapterList }
    $pAdapter.Controls.Add($btnRefresh)

    $btnFlush = New-CustomButton -Text 'Flush Cache' -X 685 -Y 33 -W 120 -H 27 -BgColor $script:Theme.Panel2 -OnClick {
        try { Clear-DnsClientCache; Write-Log 'DNS cache cleared successfully.' 'SUCCESS' } catch { Write-Log 'Failed to flush cache.' 'ERROR' }
    }
    $pAdapter.Controls.Add($btnFlush)

    $script:LblCurrentDNS = New-Object System.Windows.Forms.Label
    $script:LblCurrentDNS.Text = 'Current DNS: --'
    $script:LblCurrentDNS.ForeColor = $script:Theme.Accent
    $script:LblCurrentDNS.Location = New-Object System.Drawing.Point(180, 12)
    $script:LblCurrentDNS.AutoSize = $true
    $pAdapter.Controls.Add($script:LblCurrentDNS)

    # --- Section 2: Preset List ---
    $pGrid = New-SectionPanel -X 20 -Y 159 -W 820 -H 240
    $form.Controls.Add($pGrid)

    $script:LV = New-Object System.Windows.Forms.ListView
    $script:LV.Size = New-Object System.Drawing.Size(790, 185)
    $script:LV.Location = New-Object System.Drawing.Point(15, 12)
    $script:LV.View = [System.Windows.Forms.View]::Details
    $script:LV.FullRowSelect = $true
    $script:LV.MultiSelect = $false
    $script:LV.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $script:LV.BackColor = $script:Theme.Panel2
    $script:LV.ForeColor = $script:Theme.Text
    $script:LV.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable

    [void]$script:LV.Columns.Add('Provider', 160)
    [void]$script:LV.Columns.Add('Primary DNS', 120)
    [void]$script:LV.Columns.Add('Secondary DNS', 120)
    [void]$script:LV.Columns.Add('Description', 290)
    [void]$script:LV.Columns.Add('DNS Query', 80)
    $pGrid.Controls.Add($script:LV)
    try { [void][DnsMgr.Win32Con]::SetWindowTheme($script:LV.Handle, 'Explorer', $null) } catch {}

    # Action Buttons
    $btnApply = New-CustomButton -Text 'Apply Selected' -X 15 -Y 204 -W 180 -H 28 -BgColor $script:Theme.Accent -OnClick { Apply-SelectedPreset } -Emphasis
    $pGrid.Controls.Add($btnApply)

    $btnPing = New-CustomButton -Text 'Test DNS Query' -X 205 -Y 204 -W 180 -H 28 -BgColor $script:Theme.Panel2 -OnClick { Test-DNSSpeed }
    $pGrid.Controls.Add($btnPing)

    $btnFastest = New-CustomButton -Text 'Auto Best DNS' -X 395 -Y 204 -W 180 -H 28 -BgColor $script:Theme.Panel2 -OnClick { Select-FastestDNS }
    $pGrid.Controls.Add($btnFastest)

    $btnBackup = New-CustomButton -Text 'Restore Backup' -X 625 -Y 204 -W 180 -H 28 -BgColor $script:Theme.Panel2 -OnClick { Restore-DNSBackup }
    $pGrid.Controls.Add($btnBackup)

    # --- Section 3: Custom DNS Input ---
    $pCustom = New-SectionPanel -X 20 -Y 411 -W 820 -H 70
    $form.Controls.Add($pCustom)

    $lblP4 = New-Object System.Windows.Forms.Label
    $lblP4.Text = 'Primary IPv4:'
    $lblP4.ForeColor = $script:Theme.Subtext
    $lblP4.Location = New-Object System.Drawing.Point(15, 23)
    $lblP4.AutoSize = $true
    $pCustom.Controls.Add($lblP4)

    $script:TxtIPv4A = New-Object System.Windows.Forms.TextBox
    $script:TxtIPv4A.Location = New-Object System.Drawing.Point(95, 20)
    $script:TxtIPv4A.Size = New-Object System.Drawing.Size(150, 23)
    $script:TxtIPv4A.BackColor = $script:Theme.Panel2
    $script:TxtIPv4A.ForeColor = $script:Theme.Text
    $script:TxtIPv4A.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pCustom.Controls.Add($script:TxtIPv4A)

    $lblS4 = New-Object System.Windows.Forms.Label
    $lblS4.Text = 'Secondary IPv4:'
    $lblS4.ForeColor = $script:Theme.Subtext
    $lblS4.Location = New-Object System.Drawing.Point(265, 23)
    $lblS4.AutoSize = $true
    $pCustom.Controls.Add($lblS4)

    $script:TxtIPv4B = New-Object System.Windows.Forms.TextBox
    $script:TxtIPv4B.Location = New-Object System.Drawing.Point(365, 20)
    $script:TxtIPv4B.Size = New-Object System.Drawing.Size(150, 23)
    $script:TxtIPv4B.BackColor = $script:Theme.Panel2
    $script:TxtIPv4B.ForeColor = $script:Theme.Text
    $script:TxtIPv4B.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pCustom.Controls.Add($script:TxtIPv4B)

    $btnApplyCustom = New-CustomButton -Text 'Apply Custom' -X 625 -Y 18 -W 180 -H 27 -BgColor $script:Theme.Accent -OnClick { Apply-CustomDNS } -Emphasis
    $pCustom.Controls.Add($btnApplyCustom)

    # --- Section 4: Log Output ---
    $pLog = New-SectionPanel -X 20 -Y 493 -W 820 -H 118
    $form.Controls.Add($pLog)

    $script:TxtLog = New-Object System.Windows.Forms.RichTextBox
    $script:TxtLog.Size = New-Object System.Drawing.Size(790, 93)
    $script:TxtLog.Location = New-Object System.Drawing.Point(15, 12)
    $script:TxtLog.BackColor = $script:Theme.Panel2
    $script:TxtLog.ForeColor = $script:Theme.Text
    $script:TxtLog.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $script:TxtLog.ReadOnly = $true
    $script:TxtLog.Font = New-Object System.Drawing.Font('Consolas', 8.5)
    $pLog.Controls.Add($script:TxtLog)

    # --- Footer / Status Bar ---
    $pFooter = New-Object System.Windows.Forms.Panel
    $pFooter.Size = New-Object System.Drawing.Size(860, 28)
    $pFooter.Location = New-Object System.Drawing.Point(0, 640)
    $pFooter.BackColor = $script:Theme.Panel
    $pFooter.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen($script:Theme.Border, 1)
        $e.Graphics.DrawLine($pen, 0, 0, $s.Width, 0)
        $pen.Dispose()
    })
    $form.Controls.Add($pFooter)

    $lblFooterLeft = New-Object System.Windows.Forms.Label
    $lblFooterLeft.Text = 'DNS Manager Pro'
    $lblFooterLeft.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $lblFooterLeft.ForeColor = $script:Theme.Subtext
    $lblFooterLeft.Location = New-Object System.Drawing.Point(20, 7)
    $lblFooterLeft.AutoSize = $true
    $pFooter.Controls.Add($lblFooterLeft)

    $lblFooterRight = New-Object System.Windows.Forms.Label
    $lblFooterRight.Text = 'Credit: TQN'
    $lblFooterRight.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $lblFooterRight.ForeColor = $script:Theme.Subtext
    $lblFooterRight.AutoSize = $true
    $lblFooterRight.Location = New-Object System.Drawing.Point(770, 7)
    $pFooter.Controls.Add($lblFooterRight)

    # --- Events Binding ---
    $script:CboAdapter.Add_SelectedIndexChanged({
        if ($script:CboAdapter.SelectedIndex -ge 0) {
            $script:SelectedAdapter = $script:Adapters[$script:CboAdapter.SelectedIndex]
            Update-DNSDisplay
        }
    })

    return $form
}

# --- GUI Logic Implementation ---
function Reload-AdapterList {
    $script:CboAdapter.Items.Clear()
    $script:Adapters = Get-ActiveAdapters
    if ($script:Adapters.Count -eq 0) {
        Write-Log 'No network adapters found.' 'ERROR'
        return
    }
    foreach ($a in $script:Adapters) {
        $status = if ($a.Status -eq 'Up') { 'Connected' } else { [string]$a.Status }
        [void]$script:CboAdapter.Items.Add(("{0}  [{1}]" -f $a.Name, $status))
    }
    $script:CboAdapter.SelectedIndex = 0
    Write-Log 'Network adapters reloaded.' 'INFO'
}

function Update-DNSDisplay {
    if (-not $script:SelectedAdapter) { return }
    $info = Get-AdapterDNS -ifIndex $script:SelectedAdapter.InterfaceIndex
    $v4 = if ($info.IPv4.Count -gt 0) { $info.IPv4 -join ', ' } else { 'DHCP (Auto)' }
    $script:LblCurrentDNS.Text = "Current IPv4: $v4"
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

function Apply-SelectedPreset {
    if ($script:LV.SelectedItems.Count -eq 0 -or -not $script:SelectedAdapter) { return }
    $preset = $script:LV.SelectedItems[0].Tag
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        Backup-CurrentDNS -ifIndex $script:SelectedAdapter.InterfaceIndex -Alias $script:SelectedAdapter.Name
        Set-DNSConfig -ifIndex $script:SelectedAdapter.InterfaceIndex -Preset $preset
        Update-DNSDisplay
        Write-Log ("Applied '{0}' to {1}" -f $preset.Name, $script:SelectedAdapter.Name) 'SUCCESS'
    } catch {
        Write-Log ("Error applying DNS: {0}" -f $_.Exception.Message) 'ERROR'
    } finally {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
    }
}

function Apply-CustomDNS {
    if (-not $script:SelectedAdapter) { return }
    $ip1 = $script:TxtIPv4A.Text.Trim()
    $ip2 = $script:TxtIPv4B.Text.Trim()

    if (-not (Test-ValidIP -IP $ip1)) {
        Write-Log 'Invalid Primary IPv4 address.' 'WARN'
        return
    }
    $v4 = @($ip1)
    if ($ip2 -and (Test-ValidIP -IP $ip2)) { $v4 += $ip2 }

    $preset = @{ Name = 'Custom'; Mode = 'Manual'; IPv4 = $v4 }
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        Backup-CurrentDNS -ifIndex $script:SelectedAdapter.InterfaceIndex -Alias $script:SelectedAdapter.Name
        Set-DNSConfig -ifIndex $script:SelectedAdapter.InterfaceIndex -Preset $preset
        Update-DNSDisplay
        Write-Log ("Applied custom DNS ({0}) to {1}" -f ($v4 -join ', '), $script:SelectedAdapter.Name) 'SUCCESS'
    } catch {
        Write-Log ("Error setting custom DNS: {0}" -f $_.Exception.Message) 'ERROR'
    } finally {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
    }
}

function Test-DNSSpeed {
    $queryDomain = 'www.cloudflare.com'
    Write-Log ("Benchmarking real DNS queries for {0}..." -f $queryDomain) 'INFO'
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        foreach ($item in $script:LV.Items) {
            $preset = $item.Tag
            if ($preset.Mode -eq 'Automatic') {
                $item.SubItems[4].Text = 'N/A'
                continue
            }
            $target = $preset.IPv4[0]
            $ms = Get-DnsQueryMs -Server $target -Domain $queryDomain
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
    if ($bestItem) {
        $script:LV.SelectedItems.Clear()
        $bestItem.Selected = $true
        Apply-SelectedPreset
        Write-Log ("Auto-selected fastest DNS query server: {0} ({1} ms)" -f $bestItem.Tag.Name, $minQueryMs) 'SUCCESS'
    } else {
        Write-Log 'Could not find optimal DNS server.' 'WARN'
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
        $preset = @{ Mode = $backup.Mode; IPv4 = @($backup.IPv4); IPv6 = @($backup.IPv6) }
        Set-DNSConfig -ifIndex $script:SelectedAdapter.InterfaceIndex -Preset $preset
        Update-DNSDisplay
        Write-Log ("Restored DNS backup from {0}" -f $backup.Time) 'SUCCESS'
    } catch {
        Write-Log 'Failed to restore DNS backup.' 'ERROR'
    }
}

# --- Execution Entry ---
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
