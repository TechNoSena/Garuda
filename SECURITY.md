# 🔒 Security Policy

<div align="center">

  **Project Garuda** takes security seriously.

  *We appreciate your help in keeping Garuda and its users safe.*

</div>

---

## Supported Versions

| Version | Supported |
|:---|:---|
| Beta v1.0.0 (Latest) | ✅ Active |
| Pre-release / Dev builds | ❌ Not supported |

---

## Reporting a Vulnerability

If you discover a security vulnerability within Project Garuda, please report it responsibly.

### ⚠️ Do NOT open a public GitHub Issue for security vulnerabilities.

Instead, please email us directly:

📧 **divye.prakash07@gmail.com**

### What to include

- A clear description of the vulnerability
- Steps to reproduce the issue
- The potential impact and severity
- Any suggested fixes (if applicable)

### Response Timeline

| Stage | Timeframe |
|:---|:---|
| Acknowledgement | Within **48 hours** |
| Initial Assessment | Within **5 business days** |
| Fix & Disclosure | Within **30 days** (coordinated) |

---

## Security Best Practices for Contributors

- **Never** commit API keys, secrets, or credentials to the repository
- Always use environment variables (`.env`) for sensitive configuration
- Keep dependencies updated to avoid known vulnerabilities
- Use Firebase Security Rules to restrict unauthorized database access
- Validate and sanitize all user input on both client and server side

---

## Scope

The following components are in scope for security reports:

| Component | In Scope |
|:---|:---|
| FastAPI Backend (Cloud Run) | ✅ |
| Flutter Mobile Application | ✅ |
| Firebase Authentication & Firestore Rules | ✅ |
| Google Cloud API Key Exposure | ✅ |
| Third-party dependencies | ✅ (if exploitable via Garuda) |

---

<div align="center">

  *Thank you for helping keep Project Garuda secure — Team DietCoke*

</div>
