# Private AI Circuit — AWS Blueprint

**Run a private AI agent on AWS GPU. Your laptop stays cold. Your code never leaves your infra.**

> Hermes Desktop · Ollama · AWS EC2 · Auto-stop · Terraform

You can plug this private AI circuit into any modern development environment:
- **VS Code / Neovim:** via the popular `Continue.dev` extension.
- **Cursor / Cline / Roo Code:** just point the base URL to your EC2 instance IP.
- **JetBrains (IntelliJ, PyCharm):** via AI Assistant or third-party LLM plugins.

Your development workflow stays exactly the same — but your AI autocomplete and chat now run on a dedicated AWS GPU inside your secure perimeter.

---

## What this is

A Terraform blueprint that provisions an isolated AWS GPU instance for running local AI models (Ollama) with [Hermes Desktop](https://hermesdesktop.ai) Remote Gateway.

Your team gets:
- Unlimited AI requests — no rate limits, no per-seat licensing
- Zero data leaving your AWS account
- Auto-stop when idle — pay only for active compute
- Cold, silent laptops — all compute runs remotely

**Estimated cost:** ~$58/month for a team of 5 (4 active hours/day on g4dn.xlarge)  
**vs.** 5 × Claude Pro + ChatGPT Plus = $200/month with rate limits and your code on their servers.

---

## Architecture

```
┌─────────────────────────────────┐
│  Hermes Desktop (your laptop)   │  ← cold, silent, just a terminal
└──────────────┬──────────────────┘
               │ Remote Gateway · port 8642
               ▼
┌─────────────────────────────────┐
│  AWS EC2 — Private Circuit      │
│  ┌─────────────┐ ┌───────────┐  │
│  │ NVIDIA T4   │ │  Ollama   │  │  ← all compute here
│  │ 16GB VRAM   │ │  :11434   │  │
│  └─────────────┘ └───────────┘  │
└──────────────┬──────────────────┘
               │ GPU idle > 25 min
               ▼
┌─────────────────────────────────┐
│  CloudWatch → Lambda auto-stop  │  ← pay-as-you-go, automatic
└─────────────────────────────────┘
```

---

## Free tier vs Full Blueprint

One repository. One paid package. Here's exactly what's in each.

| | GitHub (free) | Payhip — $49 |
|---|:---:|:---:|
| **Terraform structure** | ✓ | ✓ |
| `main.tf` — root module | ✓ | ✓ |
| `variables.tf` — with validation | ✓ | ✓ |
| `versions.tf` — provider locks | ✓ | ✓ |
| `modules/ai-instance/main.tf` | ✓ | ✓ |
| `scripts/start.sh` — basic | ✓ | ✓ full version |
| `.gitignore` | ✓ | ✓ |
| **Auto-setup on first boot** | | |
| `user_data.sh` — installs NVIDIA driver, Docker, Ollama, Hermes Gateway, CloudWatch Agent automatically | — | ✓ |
| **Model management** | | |
| `pull-model.sh` — interactive selector, detects GPU/RAM, shows what fits | — | ✓ |
| **Instance management** | | |
| `stop.sh` — graceful shutdown, stops services before instance | — | ✓ |
| `start.sh` — full version with SSH health check + service status | — | ✓ |
| **Infrastructure fixes** | | |
| AMI data source (`data "aws_ami"`) | — | ✓ |
| Elastic IP — static URL after every restart | — | ✓ |
| Auto-stop on GPU utilization (not CPU) | — | ✓ |
| Lambda IAM — least-privilege, instance-scoped | ✓ | ✓ |
| **After `terraform apply`** | Manual setup (~3–4 hrs) | Working in 20 min |

**Free tier** is for engineers who want to understand the architecture and set up manually.  
**Full Blueprint** is for everyone who wants to `terraform apply` and be done.

→ **[Get the full Blueprint — $49](https://payhip.com/b/nkpSv)**  
→ **[Want it deployed in your AWS account? — from $800](https://t.me/baibakov_dmitry)**

---

## Quick start (free tier)

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.5
- SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/hermes-ai-key`
- GPU quota approved in your AWS region  
  *(Request: AWS Console → Service Quotas → EC2 → Running On-Demand G instances)*

### Deploy

⚠️ Disclaimer: ---> This blueprint deploys real infrastructure on AWS. GPU instances (such as g4dn.xlarge) are not covered by the AWS Free Tier. You will be billed by AWS for the time the instance is running and for the storage used. Remember to run terraform destroy when you are done to avoid unexpected charges.


```bash
git clone https://github.com/BaibakovDmytro/private-ai-circuit
cd private-ai-circuit

cp terraform.tfvars.example terraform.tfvars
# Edit: set your IP, region, instance type

terraform init
terraform apply
```

### After deploy

```bash
# Start instance
./scripts/start.sh

# SSH in and pull a model manually
ssh -i ~/.ssh/hermes-ai-key ubuntu@<IP>
ollama pull qwen2.5-coder:7b

# Connect Hermes Desktop → Remote URL: http://<IP>:8642
```

> **Note:** `user_data.sh` is not included in this repo.  
> After `terraform apply`, you'll have a blank Ubuntu instance.  
> You'll need to install NVIDIA drivers, Docker, Ollama, and Hermes manually — or get the full Blueprint.

---

## Instance types

| Instance | GPU | VRAM | Models | Cost/hr |
|----------|-----|------|--------|---------|
| `g4dn.xlarge` | NVIDIA T4 | 16 GB | up to 14B | ~$0.53 |
| `g5.xlarge` | NVIDIA A10G | 24 GB | up to 32B | ~$1.01 |
| `g5.4xlarge` | NVIDIA A10G | 24 GB | up to 32B, faster | ~$1.62 |

Default: `g4dn.xlarge` — best price/performance for a solo developer or small team.

---

## Cost breakdown

**Active hours only** (instance stopped when idle):

```
g4dn.xlarge × 4 hrs/day × 22 workdays  =  ~$47/mo compute
EBS 80GB gp3                            =  ~$6/mo storage
CloudWatch + Lambda                     =  ~$2/mo automation
─────────────────────────────────────────────────────────────
Total                                   =  ~$55/mo (team of 5)
```

When stopped: you pay only for EBS — about **$0.10/day**.

---

## Security notes

This free tier has known limitations:

- ⚠️ Security Group defaults to `0.0.0.0/0` — **change `my_ip` in tfvars before deploying**
- ⚠️ No Elastic IP — public IP changes after every start
- ⚠️ Lambda IAM uses broad policy — full Blueprint uses least-privilege inline policy
- ⚠️ No VPC isolation — instance runs in default VPC

All of these are fixed in the full Blueprint.

---

## FAQ

**Can I use this without Hermes Desktop?**  
Yes. Ollama exposes an OpenAI-compatible API on port 11434. Works with Continue, Cursor, or any OpenAI-compatible client.

**Which models work best?**  
For coding: `qwen2.5-coder:7b` (fast) or `qwen2.5-coder:14b` (quality). For general use: `llama3.1:8b`. Full model selector with hardware detection is in the paid Blueprint.

**What if I forget to stop the instance?**  
The CloudWatch alarm stops it automatically after 25 minutes of idle. You pay ~$0.10/day for storage while stopped.

> ⚠️ **Note on Auto-Stop:** Out of the box, this architecture uses standard AWS CPU metrics for idle detection. If you plan to run continuous batch jobs or heavy background scripts that take longer than 45 minutes of pure GPU execution without CPU load, we highly recommend increasing the `idle_minutes` variable in your `terraform.tfvars` or setting `auto_stop_enabled = false` to prevent early shutdowns.



**Does my code leave AWS?**  
No. The model runs inside your EC2 instance. Requests go from your laptop → your EC2 → back. Nothing touches OpenAI or Anthropic servers.

---

## Contributing

Issues and PRs welcome. This repo covers the free tier — feature requests for the full Blueprint go [here](https://payhip.com/b/nkpSv).

---

## License

MIT — use freely, modify freely, sell your own derivative work freely.  
Attribution appreciated but not required.

---

*Built by [Dmytro Baibakov](https://vibe.qlrscore.com) · AWS Solutions Architect*  
*Questions? [LinkedIn](https://linkedin.com/in/BaibakovDmytro) · [Telegram](https://t.me/baibakov_dmitry)*
