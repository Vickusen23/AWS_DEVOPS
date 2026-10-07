# 🌍 Terraform — Zero to Pro (Complete Teaching & Self-Study Guide)

> **One language. Every cloud.** This guide takes you from *"what is Terraform?"* to *teaching it yourself* — no prior experience assumed.

![Terraform](https://img.shields.io/badge/HashiCorp-Terraform-844FBA?logo=terraform&logoColor=white)
![Level](https://img.shields.io/badge/Level-Absolute%20Zero%20→%20Pro-brightgreen)
![Use](https://img.shields.io/badge/Use-Self--study%20%7C%20Teaching-blue)

---

## 🗺️ How to Use This Guide

| Your situation | Follow this path |
|---|---|
| 📖 **Self-study** | Read Parts 0–4 in order, do every ✅ checkpoint, finish with Part 6 exercises |
| 🧑‍🏫 **Teaching** | Use the **Lesson Plan** (Part 7). Each lesson = one Part, each ending with a live demo |
| 💼 **Interview prep** | Jump straight to the **Cheat Sheet** (Part 8) + **Interview Q&A** (Part 9) |
| 🔧 **Troubleshooting** | **Common Errors Table** (Part 6) |

**⏱️ Total time:** ~6–8 hours of hands-on practice to reach working confidence.

---

# PART 0 — Before You Start (Absolute Basics)

## 0.1 What Problem Does Terraform Solve?

Imagine building a web server. The **old way (manual):**
1. Log into AWS console → click EC2 → pick AMI → pick size → configure firewall → launch
2. Install Apache by hand
3. Repeat for the second server… third…
4. Six months later, rebuild it all from memory 🙈

Problems: slow, error-prone, impossible to reproduce, nobody knows what was actually configured.

The **Terraform way (Infrastructure as Code):**
1. Write *what you want* in a text file
2. Run `terraform apply`
3. Done — every time, identically, and the file itself is the documentation

> 🍳 **The Kitchen Analogy** (used throughout this guide):
>
> | Concept | Kitchen equivalent |
> |---|---|
> | `.tf` config file | 📄 The **recipe** |
> | `terraform apply` | 👨‍🍳 **Cooking** the meal |
> | State file (`.tfstate`) | 🧾 The **receipt** — proof of what was cooked |
> | `terraform plan` | 👀 **Taste before serving** |
> | `terraform destroy` | 🧼 **Washing the dishes** |
> | Module | 📖 A **recipe chapter** you reuse in many cookbooks |

## 0.2 What Exactly IS Terraform?

* Created by **HashiCorp** (now IBM), open-source
* A CLI tool you install on your laptop — nothing to sign up for
* Speaks **HCL** (HashiCorp Configuration Language) — simple, readable
* Connects to **3,000+ providers**: AWS, Azure, GCP, Kubernetes, GitHub, Datadog, Cloudflare…
* **Declarative**: you describe the *end result* ("I want a server"), Terraform figures out the *steps*

> 💡 **Declarative vs Imperative, in one line:**
> *Imperative:* "Walk 10 steps, turn left, open the door."
> *Declarative:* "I want to be inside the house." *(Terraform plans the route.)*

## 0.3 Install Terraform (5 minutes)

**Windows:**
```powershell
winget install Hashicorp.Terraform
```

**macOS:**
```bash
brew install terraform
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

**Verify:**
```bash
terraform version
```

✅ **Checkpoint 0:** `terraform version` prints a version number (e.g., `Terraform v1.9.x`).

---

# PART 1 — Your First Resource (15 minutes)

## 1.1 The Smallest Possible Terraform Project

Create a folder `first-steps` and one file `main.tf`:

```hcl
resource "local_file" "greeting" {
  filename = "hello.txt"
  content  = "Hello from Terraform!"
}
```

> 🧠 **Line-by-line, in plain English:**
> * `resource` → *"Create something"*
> * `"local_file"` → *"…a file on my computer"* (the `local` provider — no cloud needed!)
> * `"greeting"` → *"I'll call it 'greeting' inside my code"* (logical name)
> * `{ ... }` → *"Here are its settings"* (arguments)

## 1.2 Run the Magic Trio

```bash
terraform init     # 📥 one-time: downloads the "local" provider plugin
terraform plan     # 👀 shows: "+ local_file.greeting will be created"
terraform apply    # 🚀 creates hello.txt on your disk — type "yes" when asked
```

Open `hello.txt` — Terraform really created it. Now:

```bash
terraform destroy  # 🧹 deletes it again — type "yes"
```

✅ **Checkpoint 1:** You created and destroyed a real file using code. **This is the entire Terraform workflow.** Everything after this is just bigger versions of the same trio.

## 1.3 The Anatomy You Just Used

```hcl
BLOCK TYPE "PROVIDER_TYPE" "LOGICAL_NAME" {
  argument = value
}
```

* **Block type:** `resource`, `variable`, `output`, `provider`, `data`…
* **Provider type:** what to build (`local_file`, `aws_instance`, `azurerm_linux_web_app`…)
* **Logical name:** how *you* refer to it inside the code — never seen by AWS
* **Arguments:** settings inside the braces — each resource type has its own

---

# PART 2 — HCL: The Complete Building Blocks (45 minutes)

## 2.1 `provider` — *"Who am I talking to?"*

Tells Terraform which platform to connect to.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

You can declare **multiple providers in one project** — this is Terraform's superpower over CloudFormation:

```hcl
provider "aws"    { region = "us-east-1" }
provider "azurerm" { features {} }        # Azure in the same project!
```

## 2.2 `resource` — *"What should exist?"*

```hcl
resource "aws_s3_bucket" "photos" {
  bucket = "my-vacation-photos-2026"
}
```

* Terraform **creates** it if missing, **updates** it if your code changed, **deletes** it on `destroy`
* Every resource type is documented at `registry.terraform.io` — bookmark it

## 2.3 `variable` — *"What can the user customize?"*

```hcl
variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
  # no default → Terraform will ASK for it at apply time
}

variable "enable_encryption" {
  type    = bool
  default = true
}
```

**Ways to set variables** (most common first):

| Method | Command | Best for |
|---|---|---|
| 🥇 `-var` flag | `terraform apply -var bucket_name=my-bucket` | Quick tests |
| 🥈 `terraform.tfvars` file | `bucket_name = "my-bucket"` | Daily dev work |
| 🥉 Environment variable | `export TF_VAR_bucket_name=my-bucket` | CI/CD pipelines |
| Interactive prompt | (just run `apply`) | Demos |

## 2.4 `output` — *"What should we print when done?"*

```hcl
output "website" {
  description = "URL of the deployed site"
  value       = "https://${aws_s3_bucket.photos.bucket}.s3.amazonaws.com"
}
```

Printed at the end of every `apply` — perfect for URLs, IPs, connection strings.

## 2.5 `data` — *"Look up something that already exists"* ⭐

**Most beginners skip this — don't.** Data sources *read* existing infrastructure without managing it:

```hcl
data "aws_ami" "latest_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
# Reference: data.aws_ami.latest_linux.id
```

💡 **Why it matters:** AMIs change constantly. Hardcoding an AMI ID breaks your code in months. A data source **always finds the current one** — like `{{resolve:ssm:...}}` in CloudFormation, but native and readable.

## 2.6 `locals` — *"Reusable calculations inside my code"*

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_s3_bucket" "app" {
  bucket = "${local.name_prefix}-app-data"   # "shop-dev-app-data"
}
```

Think of locals as **variables you don't need to ask the user for** — internal shortcuts.

## 2.7 Referencing Between Resources — *"Connect the blocks"*

```hcl
resource "aws_security_group" "web" { ... }

resource "aws_instance" "server" {
  vpc_security_group_ids = [aws_security_group.web.id]   # ← reference by TYPE.NAME.ATTRIBUTE
}
```

> 🧠 **This single line does three things at once:**
> 1. Reads the security group's real AWS ID
> 2. Creates an **implicit dependency** — Terraform builds the SG *first*, automatically
> 3. If the SG changes, the instance gets updated

✅ **Checkpoint 2:** In a blank file, from memory, write a `provider "aws"`, a `variable` with a default, a `resource "aws_s3_bucket"`, and an `output` showing its name. Then verify with `terraform validate`.

---

# PART 3 — The State File: Terraform's Memory (30 minutes)

## 3.1 What Is State?

After every `apply`, Terraform writes a **JSON snapshot** of everything it built into `terraform.tfstate` in your project folder.

**Every decision Terraform makes = config (what you wrote) vs state (what it built).**

```text
Config says:   "an EC2 instance, type t3.micro"
State says:    "I already built an EC2 instance, type t2.micro"
Plan result:   "~ change instance type t2.micro → t3.micro"
```

## 3.2 The Three State Rules (Memorize These)

| Rule | Why |
|---|---|
| 🚫 **Never delete the state file** | Terraform "forgets" everything → next `apply` builds **duplicates** and bills you twice |
| 🚫 **Never edit the state file by hand** | Corrupted state = pain. Use `terraform state` commands |
| 🚫 **Never let two people `apply` at the same time** | Race condition corrupts state → use **remote state + locking** (Part 5) |

## 3.3 Useful State Commands

```bash
terraform state list                    # 📋 everything Terraform manages
terraform state show aws_instance.server  # 🔍 full details of one resource
terraform state rm aws_instance.server    # ✂️ stop managing it (does NOT delete it)
terraform import aws_s3_bucket.photos my-existing-bucket  # 🧬 adopt a resource made by hand
```

## 3.4 The Lifecycle in One Picture

```text
 YOU write code  ──►  init  ──►  plan  ──►  apply  ──►  real resources exist
                                    │                    │
                                    │                    ▼
                                    └── compares ──►  STATE FILE updated
                                    config vs state
```

✅ **Checkpoint 3:** Run `terraform state list` after your next apply and match every entry to a block in your code.

---

# PART 4 — Full Project: Web Server on AWS (90 minutes)

**Goal:** a real, secure Apache web server — Security Group + EC2 + AMI lookup + outputs. If you did the CloudFormation version of this, watch how every concept maps.

## 4.1 Project Structure

```text
terraform-demo/
├── providers.tf      # Terraform + AWS provider setup
├── variables.tf      # Inputs (like CFT Parameters)
└── main.tf           # Resources + Outputs (like CFT Resources + Outputs)
```

> 🧠 **Why split into files?** Terraform reads ALL `.tf` files in the folder as one big config. Splitting by purpose is pure organization — like chapters in a book.

## 4.2 `providers.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

> 🧠 **`~> 5.0`** means "any 5.x version, but not 6.0" — you get bug fixes without surprise breaking changes.

## 4.3 `variables.tf`

```hcl
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Target AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"      # ✅ free tier eligible
  description = "EC2 compute size"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment tag environment"
}
```

## 4.4 `main.tf`

```hcl
# 1️⃣ Always fetch the latest Amazon Linux 2023 AMI — never hardcode AMI IDs
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2️⃣ Security Group — the firewall
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP and SSH ingress"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"            # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-web-security-group" }
}

# 3️⃣ EC2 Instance — implicit dependency on the SG above
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Provisioned with Terraform [${var.environment}]</h1>" > /var/www/html/index.html
              EOF

  tags = { Name = "${var.environment}-tf-web-server" }
}

# 4️⃣ Outputs
output "web_server_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "website_url" {
  description = "Live Web Server URL"
  value       = "http://${aws_instance.web_server.public_dns}"
}
```

### 🧠 Three Terraform superpowers on display

1. **Implicit dependency** — `aws_security_group.web_sg.id` forces the SG to exist before the instance. No `DependsOn` needed.
2. **Data source lookup** — fresh AMI every time, zero maintenance.
3. **Interpolation** — `"${var.environment}-web-sg"` builds names dynamically.

## 4.5 Execute

```bash
terraform init                 # 📥 once: downloads AWS provider
terraform plan                 # 👀 verify: "Plan: 2 to add, 0 to change, 0 to destroy"
terraform apply -auto-approve  # 🚀 build it
terraform output website_url   # 🔗 print just the URL
terraform destroy -auto-approve # 🧹 tear it all down when finished
```

## 4.6 Reading `terraform plan` Like a Pro

```text
Plan: 2 to add, 0 to change, 0 to destroy.
```

| Symbol | Meaning |
|---|---|
| `+` | 🆕 will be **created** |
| `~` | 🔄 will be **updated in place** |
| `-` | 🗑️ will be **destroyed** |
| `-/+` | ♻️ will be **replaced** (destroy + recreate — watch for this on databases!) |

> ⚠️ **Teacher tip:** always show students a `-/+` on an EC2 instance and explain *why* (changing certain attributes like the AMI forces replacement). This single concept prevents real production disasters.

✅ **Checkpoint 4:** Apply, open `website_url` in a browser, see your page, then destroy. Full cycle complete.

---

# PART 5 — Production Best Practices

| # | Practice | Why it matters |
|---|---|---|
| 1 | 🗃️ **Remote state + locking** — store `terraform.tfstate` in S3, lock with DynamoDB (or native S3 locking) | Teams share one state; locking stops two applies at once |
| 2 | 🧱 **Modules** — reusable, versioned building blocks (next topic after this guide) | One 5,000-line file is unmaintainable |
| 3 | 🔐 **Never commit secrets** — use `TF_VAR_` env vars, AWS Secrets Manager, or HashiCorp Vault | Bots scan GitHub for passwords 24/7 |
| 4 | 📦 **Separate state per environment** | A dev `destroy` must never touch prod |
| 5 | ✅ **`plan` in CI/CD, reviewed before `apply`** | The plan is your audit trail |
| 6 | 🧹 **Never hand-edit console resources** | Next `plan` sees the difference and reverts it — or worse, behaves unpredictably. Use `terraform import` to adopt existing resources |

### 🔌 The Standard Remote Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "vick-devops-tf-state"
    key            = "webserver/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"   # one apply at a time
    encrypt        = true
  }
}
```

---

# PART 6 — Common Errors & Fixes (Troubleshooting Table)

| Error message | Cause | Fix |
|---|---|---|
| `Error: Inconsistent dependency lock file` | Someone changed provider versions | Run `terraform init -upgrade` |
| `Error: Missing required argument` | A required argument is absent | Check the resource docs on registry.terraform.io |
| `Error: Reference to undeclared resource` | Typo in `type.name` reference | Names are case-sensitive — check spelling |
| `Error: Error acquiring the state lock` | Another apply is running (or crashed and left a stale lock) | If sure nobody is applying: `terraform force-unlock <ID>` |
| `Error: No valid credential sources found` | AWS credentials missing/expired | Run `aws configure` or export `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` |
| `Error: creating EC2 Instance: UnauthorizedOperation` | IAM user lacks permissions | Attach the needed IAM policy (e.g., `AmazonEC2FullAccess` for practice) |
| `Error: BucketAlreadyExists` (S3) | Bucket names are **globally unique** | Add a random suffix to the bucket name |
| `Error: Cycle:` | Two resources reference each other | Restructure — one must be created first |
| `╷ Error: │` box with red corners | Just Terraform's error frame, not the error itself | Read the actual message **inside** the box |

---

# PART 7 — 🧑‍🏫 Ready-Made Lesson Plan (For Teaching)

| Lesson | Content | Duration | Demo |
|---|---|---|---|
| 1 | Part 0: What/Why IaC, kitchen analogy, install | 45 min | Install + `terraform version` |
| 2 | Part 1: First resource with `local_file` (no cloud needed) | 30 min | Live create + destroy a file |
| 3 | Part 2: All 6 building blocks | 60 min | Build S3 bucket with variables & outputs |
| 4 | Part 3: State file — the 3 rules, live demo of deleting state 😱 | 30 min | `state list`, break it in a sandbox |
| 5 | Part 4: Full EC2 project | 90 min | End-to-end deploy, show plan symbols |
| 6 | Part 5 + 6: Best practices & troubleshooting | 45 min | Walk the errors table, fix together |

**Teaching tips:**
* 🍳 Open and close every lesson with the kitchen analogy — repetition builds mental anchors
* 😱 Deliberately break things (delete state, edit console) — students remember disasters more than successes
* 🎯 End each lesson with its **Checkpoint** as a quiz

---

# PART 8 — 🎯 Cheat Sheet

```text
terraform init       → 📥 prepare folder, download providers (once)
terraform plan       → 👀 preview changes        (+ create / ~ update / - destroy)
terraform apply      → 🚀 make it real
terraform destroy    → 🧹 delete everything in state
terraform validate   → ✔️ check syntax (no cloud calls)
terraform fmt        → 🎨 auto-format code
terraform output     → 📤 show outputs
terraform state list → 📋 what's managed
terraform import     → 🧬 adopt existing resources

provider  = who to talk to          resource = what to build
variable  = user inputs             output   = printed results
data      = read existing stuff     locals   = internal shortcuts
```

**Reference syntax:** `resource_type.logical_name.attribute` → e.g. `aws_instance.web.public_ip`

## 🔁 CloudFormation → Terraform Map

| CloudFormation | Terraform |
|---|---|
| Template (YAML) | `.tf` files (HCL) |
| Stack | Working directory + state |
| `Parameters` | `variable` blocks |
| `Resources` | `resource` blocks |
| `Outputs` | `output` blocks |
| `!Ref` | `aws_thing.my_thing.id` |
| `!GetAtt` | `aws_thing.my_thing.attribute` |
| `!Sub` | `"${var.name}-suffix"` |
| Change Sets | `terraform plan` |
| Delete Stack | `terraform destroy` |
| Drift Detection | `terraform plan` (always shows drift) |

---

# PART 9 — 💼 Interview Q&A (Quick Fire)

**Q: Terraform vs CloudFormation?**
> Terraform is cloud-agnostic (3,000+ providers), uses HCL, and you manage state. CloudFormation is AWS-native, YAML/JSON, state managed by AWS, with automatic rollback.

**Q: What is the state file and why does it matter?**
> Terraform's memory of everything it built. All plans are config-vs-state diffs. Losing it causes duplicates; corrupting it breaks the project. Teams use remote state + locking.

**Q: How does Terraform know what order to build resources?**
> The dependency graph: references between resources (`aws_sg.web.id`) create implicit dependencies. Terraform builds a graph and walks it.

**Q: What happens if a resource is changed manually in the console?**
> Next `plan` shows drift and offers to revert to the code's definition. This is IaC's core promise: code is the source of truth.

**Q: How do you handle secrets?**
> Never in code. Environment variables (`TF_VAR_*`), AWS Secrets Manager, or Vault — referenced at runtime.

**Q: `terraform apply` failed halfway — now what?**
> Partially applied resources remain. Fix the error and re-run `apply` — Terraform resumes from state. In CI, lock files may need `force-unlock` after a crash.

---

# PART 10 — 🧪 Practice Exercises (The "Pro" Milestones)

1. 🌡️ **Drift detective** — deploy, change a tag in the AWS console, run `plan` → see Terraform propose the fix
2. 🌍 **Two environments, one code** — `terraform apply -var environment=prod` → second stack, zero code changes
3. 😱 **The state disaster (sandbox!)** — apply, delete `.tfstate`, run `plan` → understand why duplicates happen; then `import` the resources back
4. 🧬 **Adopt a stray** — create an S3 bucket by hand → `terraform import` it → bring it under management
5. 🔐 **Secret-safe variable** — set a variable via `TF_VAR_` env var, confirm it's not in any file
6. 🏗️ **Break the cycle** — intentionally create a circular reference, read the error, fix the dependency direction

---

> ✍️ *Mastered this? Next steps: **Terraform Modules** → **Workspaces** → **CI/CD pipelines** (GitHub Actions running plan/apply on every PR).*
>
> *Built with ☕ for learners and teachers alike.*
