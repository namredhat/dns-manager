# DNS Manager Pro

A lightweight, native Windows DNS management utility designed to make DNS configuration, benchmarking, and switching simple.

DNS Manager Pro provides a graphical interface for managing DNS servers on Windows, including **real DNS query benchmarking**, automatic fastest-DNS selection, IPv4/IPv6 configuration, DNS backup and restore, adapter detection, and DNS cache flushing.

---

## ✨ Features

* ⚡ **Real DNS Query Benchmarking**
* 🏆 **Auto Best DNS** selection
* 🌐 IPv4 and IPv6 DNS support
* 🔄 One-click DNS switching
* 🛠️ Custom IPv4 DNS configuration
* 💾 Automatic DNS configuration backup
* ↩️ Restore previous DNS configuration
* 🧹 Flush Windows DNS cache
* 🔌 Automatic network adapter detection
* 📊 DNS latency results in milliseconds
* 📝 Built-in activity log
* 🌑 Modern dark-themed GUI
* 🚀 Fast startup after first-time setup
* 🔐 Elevated Windows Scheduled Task for administrator execution
* 🖥️ Automatic Desktop shortcut creation
* 📦 No third-party runtime or external application required

---

# 🖥️ Requirements

| Requirement      | Details                                          |
| ---------------- | ------------------------------------------------ |
| Operating System | Windows 10 / Windows 11                          |
| PowerShell       | Windows PowerShell 5.1+                          |
| Architecture     | x64 / x86 depending on Windows installation      |
| Administrator    | Required during first-time setup                 |
| Internet         | Required for DNS benchmarking and DNS resolution |

The application uses native Windows components such as:

* PowerShell
* Windows Forms
* Windows Task Scheduler
* Windows networking components
* UDP DNS protocol

No separate Python, Node.js, .NET installation, or third-party runtime is required.

---

# 📥 Installation

DNS Manager Pro is a **portable application**.

There is no traditional installer.

Simply download the repository and keep the application files together.

## 1. Download the Repository

Download the project from GitHub and extract the folder.

The important files are:

```text
DoiDNS/
├── Chay-Doi-DNS.bat
├── Chay-Doi-DNS.vbs
└── Doi-DNS.ps1
```

> **Important:** Keep these files in the same folder. Do not rename or move `Doi-DNS.ps1` after the application has been configured.

---

# 🚀 First-Time Setup

The first launch performs a one-time Windows setup.

You can start the application using either:

```text
Chay-Doi-DNS.bat
```

or:

```text
Chay-Doi-DNS.vbs
```

### What happens on the first launch?

The launcher checks whether the following Windows Scheduled Task already exists:

```text
DNSManagerPro_Elevated
```

If it does not exist, the launcher starts:

```text
Doi-DNS.ps1
```

The PowerShell application then requests **Administrator privileges**.

Windows will display the UAC confirmation.

Click:

```text
Yes
```

This is required because DNS Manager Pro needs elevated privileges to modify Windows network adapter DNS settings and create its elevated Scheduled Task.

---

# ⚙️ What the First Run Configures

After receiving administrator permission, DNS Manager Pro automatically creates:

## 1. Elevated Scheduled Task

The application registers:

```text
DNSManagerPro_Elevated
```

The task is configured to:

* Run under the current Windows user
* Use an interactive logon
* Run with the **Highest Available** run level
* Start PowerShell with the DNS Manager Pro script
* Allow the task to run while on battery
* Prevent multiple instances from being started simultaneously

This task is used for subsequent launches.

---

## 2. Desktop Shortcut

The application automatically creates:

```text
DNS Manager Pro.lnk
```

on the current user's Desktop.

The shortcut launches:

```text
Chay-Doi-DNS.vbs
```

which then starts the elevated Scheduled Task.

---

# 🚀 Starting the Application After Setup

After the first-time setup is complete, you have multiple ways to launch DNS Manager Pro.

### Method 1 — Desktop Shortcut

Double-click:

```text
DNS Manager Pro
```

on your Desktop.

### Method 2 — BAT Launcher

Run:

```text
Chay-Doi-DNS.bat
```

### Method 3 — VBS Launcher

Run:

```text
Chay-Doi-DNS.vbs
```

---

# 🔐 Why You Normally Don't See UAC Again

After the first-time setup, the launcher detects:

```text
DNSManagerPro_Elevated
```

and directly asks Windows Task Scheduler to run it.

The launcher does **not** start a new `RunAs` PowerShell process each time.

The execution flow becomes:

```text
DNS Manager Pro shortcut
        │
        ▼
Chay-Doi-DNS.vbs
        │
        ▼
Check DNSManagerPro_Elevated
        │
        ▼
schtasks /run
        │
        ▼
Windows Task Scheduler
        │
        ▼
Doi-DNS.ps1
        │
        ▼
DNS Manager Pro
```

This allows the application to start with its configured elevated privileges without displaying the normal UAC elevation prompt on every launch.

> **Important:** The UAC prompt is expected during the initial setup because Windows must authorize creation of the elevated Scheduled Task. The application does not bypass Windows security; it uses Windows Task Scheduler's built-in elevated task mechanism.

---

# 🖥️ Using DNS Manager Pro

Once the application opens, the main interface contains several sections for managing and testing DNS.

---

## 1. Select a Network Adapter

DNS Manager Pro automatically detects available network adapters.

Examples:

```text
Ethernet [Connected - Hardware]
Wi-Fi [Connected - Hardware]
```

The application distinguishes between:

* Hardware network adapters
* Virtual / VPN adapters

Select the adapter whose DNS configuration you want to manage.

Use:

```text
Refresh
```

to reload the adapter list.

The currently configured DNS is displayed after selecting an adapter.

---

# 🌐 DNS Presets

DNS Manager Pro includes several predefined DNS providers.

Current presets include:

| Provider            | IPv4 Primary     | IPv4 Secondary    |
| ------------------- | ---------------- | ----------------- |
| Automatic (DHCP)    | Automatic        | Automatic         |
| Cloudflare          | `1.1.1.1`        | `1.0.0.1`         |
| Google Public DNS   | `8.8.8.8`        | `8.8.4.4`         |
| Control D           | `76.76.2.0`      | `76.76.10.0`      |
| AdGuard DNS         | `94.140.14.14`   | `94.140.15.15`    |
| Quad9 Security      | `9.9.9.9`        | `149.112.112.112` |
| Cloudflare Security | `1.1.1.2`        | `1.0.0.2`         |
| Cloudflare Family   | `1.1.1.3`        | `1.0.0.3`         |
| OpenDNS Home        | `208.67.222.222` | `208.67.220.220`  |
| NextDNS             | `45.90.28.0`     | `45.90.30.0`      |
| VNPT DNS            | `203.162.4.190`  | `203.162.4.191`   |
| Viettel DNS         | `203.113.131.1`  | `203.113.131.2`   |
| FPT Telecom         | `210.245.24.20`  | `210.245.24.22`   |
| DNS.WATCH           | `84.200.69.80`   | `84.200.70.40`    |

Several presets also contain IPv6 DNS addresses.

---

# ⚡ DNS Query Benchmark

DNS Manager Pro does **not** use a simple ICMP ping to determine DNS performance.

Instead, it sends an actual DNS request to each DNS resolver.

The benchmark uses:

```text
Domain:
www.cloudflare.com

Protocol:
UDP

Port:
53
```

## How it works

For each DNS provider:

```text
Your PC
   │
   │  DNS Query
   │  "What is the IP address of
   │   www.cloudflare.com?"
   ▼
DNS Resolver
   │
   │  DNS Response
   │  "Here are the IP addresses."
   ▼
Your PC
```

The application measures the time required to receive a valid DNS response.

For example:

```text
Cloudflare          12 ms
Google Public DNS   18 ms
Quad9               24 ms
OpenDNS             31 ms
```

A lower value means the DNS resolver responded faster during that test.

---

## 🔬 DNS Benchmark Details

For every DNS server, DNS Manager Pro:

1. Creates a UDP client.
2. Connects to the DNS server on port `53`.
3. Generates a DNS transaction ID.
4. Builds a DNS query packet.
5. Queries:

```text
www.cloudflare.com
```

6. Starts a high-resolution timer.
7. Sends the DNS query.
8. Waits for the DNS response.
9. Verifies the DNS transaction ID.
10. Checks the DNS response code.
11. Checks that the response contains an answer.
12. Stops the timer.
13. Displays the result in milliseconds.

The individual DNS query timeout is:

```text
1000 ms
```

If the resolver does not return a valid response within the timeout:

```text
Timeout
```

is displayed.

---

# 🔁 Two-Request Benchmark

Each DNS provider is queried **twice**.

The application then chooses the lower successful latency:

```text
Test #1 → 18 ms
Test #2 → 12 ms

Result → 12 ms
```

If only one request succeeds:

```text
Test #1 → Timeout
Test #2 → 20 ms

Result → 20 ms
```

If both requests fail:

```text
Result → Timeout
```

This provides a simple way to reduce the effect of a single unusually slow request.

---

# 🏆 Auto Best DNS

The **Auto Best DNS** function combines benchmarking and DNS switching.

When activated:

```text
1. Benchmark all manual DNS presets
        ↓
2. Send two real DNS queries to each resolver
        ↓
3. Ignore DNS servers that time out
        ↓
4. Compare successful query latency
        ↓
5. Find the lowest result
        ↓
6. Select the fastest DNS
        ↓
7. Apply it to the selected network adapter
```

Example:

```text
Cloudflare          14 ms
Google Public DNS   21 ms
Quad9               28 ms
AdGuard             17 ms
```

The tool selects:

```text
Cloudflare — 14 ms
```

and applies it automatically.

---

# ⚠️ Understanding DNS Speed

The benchmark measures **DNS resolver response latency**, not your Internet bandwidth.

For example:

```text
DNS latency:       12 ms
Download speed:    100 Mbps
```

These are completely different measurements.

Changing DNS generally does **not** increase your ISP's maximum:

* Download speed
* Upload speed
* Wi-Fi bandwidth

DNS mainly determines how quickly domain names can be resolved.

---

# 🔄 Applying a DNS Preset

To manually change DNS:

1. Select a network adapter.
2. Select a DNS provider.
3. Click **Apply Selected**.

You can also double-click a DNS row to apply it immediately.

Before changing the DNS configuration, DNS Manager Pro automatically creates a backup.

---

# 🛠️ Custom DNS

DNS Manager Pro also allows you to enter your own IPv4 DNS servers.

Example:

```text
Primary IPv4:
1.1.1.1

Secondary IPv4:
1.0.0.1
```

Then click:

```text
Apply Custom DNS
```

The primary IPv4 address must be valid.

The secondary IPv4 address is optional.

The application validates the entered address before applying it.

---

# 🌐 IPv6 Support

DNS Manager Pro supports IPv6 DNS configuration for presets that provide IPv6 addresses.

IPv6 configuration can be enabled or disabled through the IPv6 option in the interface.

When enabled, applying a preset can configure both:

```text
IPv4 DNS
+
IPv6 DNS
```

This allows users with IPv6 connectivity to use the corresponding IPv6 resolvers.

---

# 💾 Automatic Backup

Before applying a DNS configuration, the application automatically saves the current configuration.

The backup contains information such as:

* DNS mode
* IPv4 DNS addresses
* IPv6 DNS addresses
* Backup timestamp

The backup is stored locally at:

```text
%LOCALAPPDATA%\DNSManagerPro\backup.json
```

---

# ↩️ Restore DNS

If you want to return to your previous DNS configuration:

1. Select the appropriate network adapter.
2. Click:

```text
Restore Backup
```

The application reads the saved backup and restores the previous DNS configuration.

---

# 🧹 Flush DNS Cache

DNS Manager Pro can flush the Windows DNS cache after DNS configuration changes.

This helps Windows discard previously cached DNS resolutions.

You can also manually use the **Flush Cache** function from the interface.

---

# 📝 Activity Log

DNS Manager Pro provides a built-in activity log.

Typical messages include:

```text
[INFO] Network adapters reloaded.
[INFO] Benchmarking DNS query speeds...
[SUCCESS] DNS query benchmark completed.
[SUCCESS] Applied 'Cloudflare' to Ethernet.
```

The log is also saved locally:

```text
%LOCALAPPDATA%\DNSManagerPro\activity.log
```

---

# 📁 File Structure

The repository is intentionally simple:

```text
dns-manager/
│
├── DoiDNS/
│   ├── Chay-Doi-DNS.bat
│   ├── Chay-Doi-DNS.vbs
│   └── Doi-DNS.ps1
│
└── README.md
```

### `Doi-DNS.ps1`

The main application.

Responsible for:

* GUI
* Network adapter detection
* DNS configuration
* IPv4 / IPv6 management
* DNS benchmarking
* Automatic DNS selection
* Backup / restore
* Logging
* Scheduled Task registration
* Desktop shortcut creation

### `Chay-Doi-DNS.bat`

Command-line launcher.

It:

1. Changes the working directory to the application's folder.
2. Checks whether `DNSManagerPro_Elevated` exists.
3. If it exists, starts the Scheduled Task.
4. If it does not exist, launches the PowerShell application for first-time setup.

### `Chay-Doi-DNS.vbs`

Silent launcher.

It performs the same basic startup logic without displaying a command prompt window.

---

# 🔐 Security & Permissions

DNS Manager Pro requires elevated privileges because changing Windows network adapter DNS configuration is an administrative operation.

The application uses the Windows Task Scheduler mechanism to create:

```text
DNSManagerPro_Elevated
```

with:

```text
RunLevel = Highest
LogonType = Interactive
```

The application does **not** attempt to disable UAC globally or modify Windows security settings.

The first-time UAC confirmation authorizes the creation of the elevated task.

After that, Windows Task Scheduler is responsible for launching the registered task with its configured privileges.

---

# 🧩 No Installation Wizard

DNS Manager Pro does not install a traditional program package.

It works directly from the downloaded folder.

This means:

* No MSI installer
* No registry-based application installation required
* No third-party runtime
* No Python installation
* No Node.js installation

The application stores its runtime data under:

```text
%LOCALAPPDATA%\DNSManagerPro
```

and registers one Windows Scheduled Task:

```text
DNSManagerPro_Elevated
```

---

# 🗑️ Uninstall / Remove

Because DNS Manager Pro is portable, removing the application mainly consists of removing the Scheduled Task and local application data.

### Remove the Scheduled Task

Open **Command Prompt as Administrator** and run:

```cmd
schtasks /delete /tn "DNSManagerPro_Elevated" /f
```

### Remove local application data

Delete:

```text
%LOCALAPPDATA%\DNSManagerPro
```

### Remove Desktop Shortcut

Delete:

```text
Desktop\DNS Manager Pro.lnk
```

After that, the downloaded DNS Manager Pro folder can be deleted normally.

---

# 🛠️ Troubleshooting

## The application asks for UAC

This is expected during the first-time setup.

The initial UAC confirmation is required to register the elevated Scheduled Task.

---

## The Desktop shortcut does not appear

Make sure the first launch completed successfully with Administrator privileges.

The application creates:

```text
DNS Manager Pro.lnk
```

on the current user's Desktop.

You can still launch the application using:

```text
Chay-Doi-DNS.bat
```

or:

```text
Chay-Doi-DNS.vbs
```

---

## DNS changes are not applied

Make sure:

* The correct network adapter is selected.
* The adapter is active.
* The application has completed its elevated setup.
* The DNS addresses are valid.

---

## DNS Benchmark shows `Timeout`

Possible reasons include:

* The DNS resolver is unreachable.
* UDP port 53 is blocked.
* The current network cannot reach that resolver.
* Temporary network problems.
* The DNS resolver did not respond within the timeout.

A timeout during one benchmark does not necessarily mean the DNS provider is permanently unavailable.

---

## Benchmark results change

This is normal.

DNS latency depends on:

* ISP routing
* Physical distance
* Network congestion
* Current network conditions
* DNS resolver load
* IPv4/IPv6 routing

Therefore, a DNS server that is fastest at one moment may not always be fastest later.

---

# 📌 Important Limitations

The current benchmark uses one DNS domain:

```text
www.cloudflare.com
```

and performs two queries per DNS provider.

Therefore, the result should be interpreted as:

> **The response latency of this DNS resolver for this test at this particular moment and network location.**

It is not a universal ranking of DNS providers.

For more comprehensive benchmarking, future versions may test multiple domains and calculate statistical values such as median and average latency.

---

# 🗺️ Roadmap

Potential future improvements include:

* [ ] Multi-domain DNS benchmarking
* [ ] Median / average latency
* [ ] DNS reliability percentage
* [ ] Packet-loss statistics
* [ ] Benchmark history
* [ ] Benchmark charts
* [ ] More DNS providers
* [ ] Custom IPv6 DNS input
* [ ] DNS-over-HTTPS support
* [ ] DNS-over-TLS support
* [ ] DNS profile import/export
* [ ] Automatic periodic benchmarking

---

# 🤝 Contributing

Contributions, bug reports, and feature requests are welcome.

If you discover a problem:

1. Open a GitHub Issue.
2. Describe the problem.
3. Include your Windows version.
4. Include relevant application log output when possible.
5. Explain how to reproduce the issue.

Pull requests are also welcome.

---

# 📄 License

This project is distributed under the license included in this repository.

See:

```text
LICENSE
```

for the complete license terms.

---

# ⭐ Summary

DNS Manager Pro provides a simple way to manage Windows DNS without manually navigating through network settings.

The typical workflow is:

```text
First Launch
     │
     ▼
Administrator Approval
     │
     ▼
Create Elevated Scheduled Task
     │
     ▼
Create Desktop Shortcut
     │
     ▼
DNS Manager Pro
     │
     ├── Select Network Adapter
     │
     ├── Test Real DNS Queries
     │
     ├── Compare Latency
     │
     ├── Auto Select Fastest DNS
     │
     ├── Apply DNS
     │
     ├── Backup Configuration
     │
     ├── Restore Previous DNS
     │
     └── Flush DNS Cache
```

After the one-time setup:

```text
DNS Manager Pro
      │
      ▼
Chay-Doi-DNS.vbs / .bat
      │
      ▼
DNSManagerPro_Elevated
      │
      ▼
Application starts elevated
```

**Fast. Simple. Portable. Native Windows DNS management.**
