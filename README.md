# 🕵️ GHOST HUNTER - Anonymous Bug Bounty Tool

> ⚠️ **Educational Purposes Only** - This tool is for learning and authorized security testing only. Unauthorized access to systems is illegal.

## ⚖️ Legal Disclaimer

**IMPORTANT:** This tool is provided for **educational purposes only**. 

- Only use on systems you own or have explicit written permission to test
- Unauthorized access, scanning, or testing is illegal and punishable by law
- The author is not responsible for any misuse or illegal activities
- By using this tool, you agree to use it responsibly and legally

---

## 📖 Description

Ghost Hunter is an anonymity and privacy tool designed for bug bounty hunters and security researchers who need to protect their identity while conducting authorized security research.

### 🔒 What This Tool Does

- Routes all traffic through Tor network for anonymity
- Rotates IP addresses automatically or manually
- Spoofs MAC addresses for network-level anonymity
- Rotates User-Agent strings to avoid fingerprinting
- Supports dark web (.onion) access via Tor
- Provides privacy-preserving HTTP request functions

---

## ✨ Features

| Feature | Description |
|---------|------------|
| **Tor Integration** | Automatic Tor setup and management |
| **IP Rotation** | Manual (`rotate`) and auto (`auto`) IP changes |
| **MAC Spoofing** | Random MAC address generation with vendor spoofing |
| **User-Agent Rotation** | Random UA from updated browser list |
| **Dark Web Support** | Direct `.onion` site access |
| **Auto-Rotate** | Configurable automatic IP rotation |
| **Privacy Headers** | DNT, Accept-Language headers |
| **Silent Logging** | URLs hidden in logs |

---

## 🚀 Installation

```bash
# Clone or download the script
https://github.com/BotGJ16/Ghost-Hunter.git
cd ghost-hunter

# Make executable
chmod +x ghost-hunter.sh
```

---

## 💻 Usage

### Required: Install Dependencies

```bash
sudo apt update
sudo apt install tor curl net-tools openssl
```

### Commands

| Command | Description |
|---------|------------|
| `sudo ./ghost-hunter.sh start` | Start Tor and setup |
| `sudo ./ghost-hunter.sh status` | Show current IP/MAC |
| `sudo ./ghost-hunter.sh rotate` | Manual IP change (NEWNYM) |
| `sudo ./ghost-hunter.sh full` | Full restart = new IP |
| `sudo ./ghost-hunter.sh mac` | Spoof MAC address |
| `sudo ./ghost-hunter.sh restore` | Restore original MAC |
| `sudo ./ghost-hunter.sh auto 300` | Auto-rotate every 300s |
| `sudo ./ghost-hunter.sh stop` | Stop Tor |

### Making Requests

```bash
# Load functions
source ./ghost-hunter.sh

# Normal request
gh_request https://example.com

# POST request
gh_request https://api.example.com POST '{"key":"value"}'

# Dark web (.onion) request
gh_onion http://example.onion
```

---

## ⚠️ Important Notes

### Limitations

- **Browser Isolation**: This tool routes terminal/CURL traffic. Browser must be configured separately:
  - Firefox: Set SOCKS proxy to `127.0.0.1:9050`
  - Or use Tor Browser for best results

- **No JavaScript Protection**: Use NoScript or disabled JS in browser

- **DNS Leaks**: Ensure `/etc/resolv.conf` uses Tor DNS (default with Tor)

- **Complete Anonymity Requires**: VPN + Tor + Proxy Chain for maximum privacy

### Best Practices

1. **Authorized Testing Only**: Only test systems you own or have permission for
2. **Keep Tor Updated**: Use latest Tor Browser for security fixes
3. **Don't Share Real Identities**: Don't login to personal accounts while using Tor
4. **Clear Cookies**: Delete browser cookies before/after anonymous sessions
5. **Check for Leaks**: Visit https://ipleak.net to verify anonymity

---

## 🔧 Troubleshooting

### Tor Not Connecting

```bash
# Check Tor status
ps aux | grep tor

# Manual start
sudo /usr/bin/tor --runasdaemon 1

# Wait 15 seconds
sleep 15

# Test connection
curl --socks5 127.0.0.1:9050 ifconfig.me
```

### IP Not Changing

```bash
# Use full restart for guaranteed new IP
sudo ./ghost-hunter.sh full
```

### Browser Not Using Tor

Configure Firefox:
1. Go to `about:config`
2. Set `network.proxy.socks` = `127.0.0.1`
3. Set `network.proxy.socks_port` = `9050`
4. Set `network.proxy.type` = `1`

---

## 📝 License

**MIT License** - See LICENSE file for details.

This software is provided "as is" without warranty. Use at your own risk.

---

## 🙏 Acknowledgments

- [Tor Project](https://www.torproject.org/) - For the Tor network
- Open source security community

---

**Remember**: Stay safe, stay legal. Happy hacking! 🔒
