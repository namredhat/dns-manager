# DNS Manager Pro

A lightweight Windows DNS management utility with a modern dark-themed GUI.

**DNS Manager Pro** allows you to quickly switch DNS providers, test real DNS query latency, automatically select the fastest tested resolver, restore your previous DNS configuration, flush the DNS cache, and configure custom IPv4 DNS servers.

> **Platform:** Windows 10 / Windows 11
> **Requirements:** PowerShell + Administrator privileges
> **Interface:** Windows Forms
> **License:** See the repository license

---

## ✨ Features

* 🎯 **One-click DNS switching**
* ⚡ **Real DNS Query benchmarking**
* 🏆 **Auto Best DNS selection**
* 🌐 Support for **IPv4 and IPv6** DNS presets
* 🛠️ **Custom IPv4 DNS configuration**
* 💾 Automatic backup before changing DNS
* ↩️ **Restore previous DNS configuration**
* 🧹 **Flush DNS cache**
* 🔌 Detects available network adapters automatically
* 📝 Built-in activity log
* 🌑 Modern dark-themed interface
* 🔐 Automatically requests Administrator privileges when required
* 🚫 No third-party software or external dependencies required

---

## 📋 Supported DNS Providers

The tool currently includes the following presets:

| Provider                | Primary IPv4     | Secondary IPv4    | Purpose                                   |
| ----------------------- | ---------------- | ----------------- | ----------------------------------------- |
| **Automatic (DHCP)**    | —                | —                 | Restore DNS provided by your router / ISP |
| **Google DNS**          | `8.8.8.8`        | `8.8.4.4`         | General-purpose public DNS                |
| **Cloudflare**          | `1.1.1.1`        | `1.0.0.1`         | Fast public resolver with privacy focus   |
| **Cloudflare Security** | `1.1.1.2`        | `1.0.0.2`         | Malware and phishing filtering            |
| **Quad9 Security**      | `9.9.9.9`        | `149.112.112.112` | Security-focused DNS                      |
| **OpenDNS Home**        | `208.67.222.222` | `208.67.220.220`  | Stable public resolver with filtering     |
| **AdGuard DNS**         | `94.140.14.14`   | `94.140.15.15`    | Ad and tracker blocking                   |
| **Control D**           | `76.76.2.0`      | `76.76.10.0`      | Configurable public resolver              |

The presets also contain IPv6 DNS addresses where supported.

---

# 🚀 Getting Started

## 1. Download the Repository

Download or clone this repository:

```bash
git clone https://github.com/namredhat/dns-manager.git
```

Or download the repository as a ZIP file from GitHub and extract it.

---

## 2. Run the Tool

Open the `DoiDNS` folder and double-click:

```text
Chay-Doi-DNS.bat
```

The launcher executes:

```text
Doi-DNS.ps1
```

PowerShell is started with:

```text
-NoProfile
-ExecutionPolicy Bypass
```

The application will then request Administrator privileges automatically if necessary.

> **Important:** Changing Windows DNS settings requires administrator privileges.

---

# 🖥️ How to Use

## 1. Select a Network Adapter

When the application starts, it automatically detects available hardware network adapters.

The adapter list displays their current state, for example:

```text
Ethernet [Connected]
Wi-Fi [Connected]
```

Select the adapter whose DNS configuration you want to modify.

Use:

**Refresh**

to reload the available network adapters.

---

## 2. View Current DNS

The application displays the currently configured IPv4 DNS servers:

```text
Current IPv4: 1.1.1.1, 1.0.0.1
```

If no manual DNS is configured, it displays:

```text
Current IPv4: DHCP (Auto)
```

---

# ⚡ Test DNS Query

One of the main features of DNS Manager Pro is its **real DNS query benchmark**.

Click:

```text
Test DNS Query
```

The tool tests each configured DNS provider individually.

### How does it work?

Instead of simply pinging the DNS server, the application sends an actual DNS request.

For example, it asks:

```text
www.cloudflare.com
```

The process is approximately:

```text
Your PC
   │
   │ DNS query:
   │ "What is the IP address of www.cloudflare.com?"
   ▼
DNS Server
   │
   │ DNS response
   ▼
Your PC
```

The tool measures the time between sending the DNS request and receiving the valid DNS response.

For example:

```text
Cloudflare       12 ms
Google DNS       18 ms
Quad9            24 ms
OpenDNS          31 ms
```

Lower values mean the DNS resolver responded faster **for that particular test**.

---

## 🔬 Technical Details of the DNS Benchmark

The benchmark is intentionally performed against the DNS server directly.

For each provider, the tool:

1. Creates a UDP connection to the DNS server.
2. Connects to port `53`.
3. Generates a random DNS transaction ID.
4. Builds a standard recursive DNS query.
5. Queries:

```text
www.cloudflare.com
```

6. Starts a high-resolution stopwatch.
7. Sends the DNS packet.
8. Waits for the DNS response.
9. Verifies the transaction ID.
10. Checks the DNS response code.
11. Checks that the response contains at least one answer.
12. Stops the timer.
13. Displays the result in milliseconds.

The default timeout is:

```text
1200 ms
```

If a valid response is not received within the timeout, the result is shown as:

```text
Timeout
```

### Why use a real DNS query instead of Ping?

A traditional ping measures ICMP network latency:

```text
PC ───── ICMP ─────> DNS Server
PC <──── ICMP ────── DNS Server
```

A DNS query measures the actual operation that DNS is responsible for:

```text
PC ───── DNS Query ─────> Resolver
PC <──── DNS Response ─── Resolver
```

Therefore, the DNS Query benchmark is more relevant when comparing **DNS resolver responsiveness**.

> **Note:** DNS query latency is not the same as Internet speed. A faster DNS resolver does not increase your download or upload bandwidth.

---

# 🏆 Auto Best DNS

Click:

```text
Auto Best DNS
```

The tool will:

```text
1. Test all available DNS presets
        ↓
2. Collect DNS query latency
        ↓
3. Ignore timed-out servers
        ↓
4. Find the lowest latency result
        ↓
5. Select the corresponding DNS
        ↓
6. Apply it to the selected network adapter
```

Example:

```text
Google DNS       19 ms
Cloudflare       11 ms   ← Fastest
Quad9            25 ms
OpenDNS          32 ms
```

The tool automatically selects:

```text
Cloudflare — 11 ms
```

and applies it to the selected adapter.

---

# 🔄 Applying a DNS Preset

Select a DNS provider from the list and click:

```text
Apply Selected
```

Before changing the configuration, DNS Manager Pro automatically creates a backup of the current DNS configuration.

It then:

1. Saves the current DNS settings.
2. Applies the selected DNS servers.
3. Clears the Windows DNS cache.
4. Updates the displayed DNS information.
5. Writes the operation to the activity log.

---

# 🛠️ Custom DNS

You can also enter your own IPv4 DNS servers.

Example:

```text
Primary IPv4:   1.1.1.1
Secondary IPv4: 1.0.0.1
```

Then click:

```text
Apply Custom
```

The primary IPv4 address is required.

The secondary address is optional.

The tool validates IPv4 addresses before applying them.

---

# ↩️ Restore Previous DNS

Before applying a new DNS configuration, the tool automatically backs up the previous configuration.

Click:

```text
Restore Backup
```

to restore the saved configuration.

The backup contains:

* Network adapter
* DNS mode
* IPv4 DNS servers
* IPv6 DNS servers
* Backup timestamp

This makes it easy to return to your previous DNS configuration.

---

# 🧹 Flush DNS Cache

Windows caches DNS results locally.

After changing DNS settings, DNS Manager Pro automatically attempts to clear the Windows DNS cache.

You can also manually click:

```text
Flush Cache
```

to execute a DNS cache flush.

This can help ensure that previously cached DNS results do not interfere with testing.

---

# 📁 Data & Logs

The application stores its local data under:

```text
%LOCALAPPDATA%\DNSManagerPro
```

The directory may contain:

```text
DNSManagerPro/
├── backup.json
└── activity.log
```

### `backup.json`

Stores the most recent DNS configuration backup.

### `activity.log`

Stores application activity such as:

```text
[18:20:01] [INFO] Network adapters reloaded.
[18:20:05] [INFO] Benchmarking real DNS queries...
[18:20:08] [SUCCESS] DNS query benchmark completed.
[18:20:15] [SUCCESS] Applied 'Cloudflare' to Ethernet
```

---

# 🔐 Administrator Privileges

DNS Manager Pro needs administrator privileges because Windows restricts modification of network adapter DNS settings.

If the application is not running as Administrator, it attempts to restart itself with elevated privileges.

You may see the Windows UAC prompt:

```text
User Account Control
```

Choose:

```text
Yes
```

to allow the application to modify network configuration.

---

# 📂 Project Structure

```text
dns-manager/
│
├── DoiDNS/
│   ├── Doi-DNS.ps1
│   └── Chay-Doi-DNS.bat
│
└── README.md
```

### `Doi-DNS.ps1`

The main application containing:

* GUI
* DNS configuration logic
* DNS benchmarking
* Network adapter detection
* Backup / restore
* Logging
* Preset management

### `Chay-Doi-DNS.bat`

A simple launcher that starts the PowerShell application.

---

# ⚙️ Technical Overview

DNS Manager Pro is built entirely with native Windows technologies.

### Core technologies

* **PowerShell**
* **Windows Forms**
* **System.Net.Sockets.UdpClient**
* **System.Net.NetworkInformation**
* **Windows DNS Client APIs / cmdlets**
* **IPv4 / IPv6**
* **UDP DNS protocol**

The DNS benchmark does not depend on external benchmarking services.

The DNS query is constructed and sent directly to the selected resolver over:

```text
UDP/53
```

---

# ⚠️ Important Notes

### DNS latency is location-dependent

There is no universally fastest DNS server.

For example:

```text
Cloudflare → 10 ms
Google     → 15 ms
Quad9      → 30 ms
```

on one network does not mean the same results will occur on another network.

Latency depends on factors such as:

* Your ISP
* Physical location
* Network routing
* DNS server location
* Network congestion
* IPv4/IPv6 connectivity
* Temporary server conditions

### The benchmark is a snapshot

DNS Manager Pro currently benchmarks the domain:

```text
www.cloudflare.com
```

A single DNS query should not be interpreted as a complete measurement of overall DNS performance.

For more reliable comparisons, multiple queries against multiple domains could be used in a future version.

### DNS speed ≠ Internet speed

Changing DNS does **not** directly increase:

* Download bandwidth
* Upload bandwidth
* Maximum ISP speed

DNS mainly affects how quickly domain names are resolved into IP addresses.

---

# 🛡️ Privacy

DNS Manager Pro does not require an online account or a third-party benchmarking website.

DNS benchmark requests are sent directly to the DNS servers being tested.

The application itself stores local configuration backups and activity logs under:

```text
%LOCALAPPDATA%\DNSManagerPro
```

The DNS providers you use may have their own privacy policies and logging practices.

---

# 🐛 Troubleshooting

## The application does not start

Make sure you are running:

```text
Chay-Doi-DNS.bat
```

and that PowerShell is available on your Windows installation.

---

## DNS changes are not applied

Try running the launcher again and allow the Administrator/UAC prompt.

Also make sure the selected network adapter is active.

---

## DNS Query shows `Timeout`

A timeout may occur because:

* The DNS server is unreachable from your network.
* UDP/53 traffic is blocked.
* The resolver temporarily does not respond.
* Your network has connectivity problems.

A timeout does not necessarily mean the DNS provider is permanently unavailable.

---

## The benchmark result changes between tests

This is normal.

Network routing and server conditions can change over time. DNS latency should therefore be treated as a measurement of current conditions rather than a permanent ranking.

---

# 🚧 Roadmap

Potential future improvements:

* [ ] Multi-query DNS benchmarking
* [ ] Median / average latency calculation
* [ ] Multiple test domains
* [ ] DNS reliability percentage
* [ ] Packet-loss detection
* [ ] DNS-over-HTTPS support
* [ ] DNS-over-TLS support
* [ ] Custom IPv6 DNS input
* [ ] Import / export DNS profiles
* [ ] More DNS providers
* [ ] Benchmark history and charts
* [ ] Background DNS monitoring

---

# 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome.

If you find a bug or have an improvement:

1. Open an **Issue**.
2. Describe the problem clearly.
3. Include your Windows version and relevant log output when possible.
4. For feature requests, explain the expected behavior.

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

## ⭐ Why DNS Manager Pro?

Instead of manually opening Windows network settings every time you want to change DNS, DNS Manager Pro puts the most common operations into one interface:

```text
Select Adapter
      ↓
Choose DNS
      ↓
Test Real DNS Query
      ↓
Compare Latency
      ↓
Apply
      ↓
Automatic Backup
```

Simple, lightweight, and designed specifically for quickly managing DNS on Windows.

---

**DNS Manager Pro**
*DNS Configuration & Optimization Utility*
