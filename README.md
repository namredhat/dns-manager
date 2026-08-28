# DNS Manager

### Fast DNS Switching, Latency Testing & Domain DNS Analysis

**DNS Manager** is a lightweight and powerful DNS management tool developed by **TQN**, a Vietnamese developer/team.

It is designed to make DNS management simple, fast, and convenient — allowing you to switch DNS servers, measure DNS latency, test DNS resolution for specific domains, and manage custom DNS servers from one place.

---

## ✨ Features

* 🚀 **DNS Latency Test**
  Measure DNS response time in milliseconds (ms).

* 🌐 **Domain DNS Latency Test**
  Check how quickly different DNS servers can resolve a specific domain.

* ⚡ **Fast DNS Switching**
  Quickly change your system DNS without manually configuring network settings.

* 📋 **Popular DNS Providers**
  Choose from a selection of widely used DNS providers.

* ➕ **Custom DNS Servers**
  Add and test your own DNS servers.

* 📊 **DNS Comparison**
  Compare multiple DNS servers and see their response times.

* 🔄 **Easy DNS Management**
  Manage, test, and switch DNS servers from one convenient tool.

* 💻 **Lightweight & Simple**
  No complicated installation process or unnecessary software.

---

# 📥 Installation & Usage

Getting started is extremely simple.

### 1. Download the Project

Download or clone this repository from GitHub.

After downloading, locate the following folder:

```text
DoiDNS
```

You do **not** need to install a complicated setup or build process to start using the tool.

---

### 2. Start the Tool

Open the `DoiDNS` folder and run:

**[Chay-Doi-DNS.bat](https://github.com/namredhat/dns-manager/blob/main/DoiDNS/Chay-Doi-DNS.bat)**

This `.bat` file is simply the **launcher** used to start the DNS Manager.

Once launched, the tool will open and you can begin using its features.

---

# 🧩 Project Structure

The project is intentionally kept simple and transparent.

```text
DoiDNS/
│
├── Chay-Doi-DNS.bat
└── Doi-DNS.ps1
```

### `Chay-Doi-DNS.bat`

**[View Chay-Doi-DNS.bat](https://github.com/namredhat/dns-manager/blob/main/DoiDNS/Chay-Doi-DNS.bat)**

This file is only the **startup/launcher file**.

Its main purpose is to launch the actual DNS Manager tool.

It does not contain the main functionality of the application.

---

### `Doi-DNS.ps1`

**[View Doi-DNS.ps1](https://github.com/namredhat/dns-manager/blob/main/DoiDNS/Doi-DNS.ps1)**

This is the **main source code of DNS Manager**.

The core functionality of the tool is contained here, including DNS management, DNS testing, latency measurement, domain resolution testing, and other features.

Because the main functionality is contained in an accessible PowerShell source file, users can **read, inspect, audit, and analyze the code themselves**.

---

# 🎯 What Can You Use It For?

DNS Manager can help you:

* Find DNS servers with lower response latency.
* Compare popular DNS providers.
* Test DNS performance for a specific domain.
* Quickly switch between different DNS configurations.
* Test custom DNS servers.
* Troubleshoot slow DNS resolution.
* Understand how different DNS servers perform on your network.

---

# 🌐 DNS Server vs Domain Latency

DNS Manager provides two useful ways to test performance.

### DNS Server Test

Measures the response time of a DNS server:

```text
Your Device
     │
     ▼
DNS Server
     │
     ▼
Response: 15 ms
```

### Domain DNS Test

Tests how quickly a DNS server resolves a specific domain:

```text
Your Device
     │
     ▼
DNS Server
     │
     ▼
example.com
     │
     ▼
DNS Resolution
     │
     ▼
Response: 18 ms
```

This makes it easier to compare how different DNS providers perform with real domains.

---

# 📊 Example

For example, you may test:

```text
Cloudflare DNS
Google DNS
Quad9
AdGuard DNS
OpenDNS
Custom DNS
```

And receive results such as:

```text
Cloudflare DNS    → 12 ms
Google DNS        → 18 ms
Quad9 DNS         → 24 ms
Custom DNS        → 31 ms
```

You can then choose the DNS that works best for your particular network.

> **Important:** The lowest DNS latency does not necessarily mean the fastest overall Internet connection. DNS is only one part of network performance.

---

# ⚠️ Important

DNS performance can vary depending on:

* Your Internet Service Provider (ISP)
* Your geographical location
* Network congestion
* DNS server load
* Routing conditions
* The domain being tested
* Your current network conditions

Therefore, the fastest DNS for one person may not be the fastest DNS for another.

**Testing directly on your own network is the best way to determine which DNS works well for you.**

---

# 🔍 Transparency & Security

DNS Manager is designed to be **simple, lightweight, and transparent**.

The main functionality is provided through the publicly accessible:

**[Doi-DNS.ps1](https://github.com/namredhat/dns-manager/blob/main/DoiDNS/Doi-DNS.ps1)**

You are free to inspect the source code and review how the tool works before using it.

You can also independently analyze, audit, or scan the project with your own security tools if you want to verify its behavior.

**Always review software yourself if security is important to you.**

---

# 🇻🇳 Made in Vietnam

## Proudly Made by Vietnamese Developers

**DNS Manager is a product from Vietnam 🇻🇳, developed by TQN with passion and dedication.**

This project was created with one simple goal:

> **Make DNS management more convenient, accessible, and easy for everyone.**

No unnecessary complexity.

No complicated installation.

Just download the project, run the launcher, and start managing your DNS.

---

# ❤️ Built with Passion

This project is made by people who care about creating useful and convenient tools.

We believe users should be able to understand what they are running on their computers.

That's why the main source code is available for everyone to inspect.

**You can take the project, examine the source code, analyze it, and perform your own security checks whenever you want.**

We encourage transparency and independent verification.

---

# ⭐ Support the Project

If **DNS Manager** is useful to you, consider giving the repository a ⭐ on GitHub.

Your support helps motivate continued development and future improvements.

---

# 🇻🇳 A Vietnamese Project, Made with Passion

**DNS Manager**

**Switch. Test. Compare. Manage.**

> 🇻🇳 **Proudly made in Vietnam by TQN and passionate developers.**
>
> **Simple. Convenient. Transparent. Open to inspection.**
>
> **Download it, inspect it, test it, and verify it yourself.**
