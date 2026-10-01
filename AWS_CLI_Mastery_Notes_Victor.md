# ☁️ AWS CLI Mastery Notes — From Absolute Zero to Pro
**Prepared for:** Victor Pius Usen (AWS SAA | CCP) | **Date:** October 2026
**How to use this note:** Read sections in order. Type EVERY command yourself in your terminal — do not copy-paste. Repetition builds muscle memory.

---

## 🧠 PART 1 — WHAT IS THE AWS CLI (AND WHY YOU MUST LEARN IT)

### 1.1 The Simple Truth
The AWS CLI is a **program installed on your computer** that talks directly to AWS's APIs. Everything you click in the AWS Console (the browser) is an API call — the CLI just makes those same calls from your terminal.

> 💡 **Why pros use CLI instead of Console:**
> 1. **Speed** — creating 10 S3 buckets = 10 clicks × 10 buckets in console, OR one CLI command.
> 2. **Repeatability** — commands can be saved in scripts (`.sh` files) and run again anytime.
> 3. **Automation** — DevOps is built on automating what humans click. Terraform, CI/CD pipelines, and scripts all call AWS APIs the same way.
> 4. **Documentation** — your terminal history *is* your documentation.

### 1.2 The Universal Command Pattern
Every single AWS CLI command follows this pattern. Memorize it:

```
aws  <service>  <action>  [parameters/flags]

aws  s3         ls
aws  ec2        run-instances    --image-id ami-xxxx --instance-type t3.micro
aws  iam        list-users
```

- `aws` → the program itself
- `<service>` → which AWS service (s3, ec2, iam, rds, lambda, vpc...)
- `<action>` → what to do (ls, cp, create-bucket, describe-instances)
- `[parameters]` → the details (names, IDs, regions)

### 1.3 Naming Convention Logic
AWS follows a predictable naming scheme, so you can often *guess* commands:
- `describe-*` = read/list things → `describe-instances`, `describe-vpcs`
- `create-*` = make new things → `create-bucket`, `create-user`
- `delete-*` = remove things → `delete-bucket`, `delete-user`
- `run-*` = start something → `run-instances`
- `stop-*` / `start-*` / `terminate-*` = control lifecycle

---

## ⚙️ PART 2 — INSTALLATION & FIRST SETUP

### 2.1 Installing the CLI
**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
**Windows:** Download the MSI installer from AWS docs, or `winget install Amazon.AWSCLI`
**Mac:** `brew install awscli`

**Verify installation:**
```bash
aws --version
# Expected: aws-cli/2.x.x Python/3.x ...
```

### 2.2 Getting Your Credentials (Security Checkpoint 🚨)
The CLI needs keys to prove it's you. NEVER use your root account keys for CLI work — create an IAM user instead:

1. AWS Console → IAM → Users → Create user (e.g., `victor-cli`)
2. Attach policy: `AdministratorAccess` (ok for learning; use least-privilege later)
3. Security credentials tab → Create access key → choose "CLI"
4. Save the **Access Key ID** and **Secret Access Key** immediately (shown once!)

### 2.3 `aws configure` — Your First Command
```bash
aws configure
```
It asks 4 things interactively:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Where this data is stored** (important to understand):
| File | Contains |
|---|---|
| `~/.aws/credentials` | Your access key ID + secret key |
| `~/.aws/config` | Default region + output format |

You can view them anytime:
```bash
cat ~/.aws/credentials
cat ~/.aws/config
```

### 2.4 Test It Works
```bash
aws sts get-caller-identity
```
This calls the Security Token Service to ask AWS "who am I?" Expected output:
```json
{
    "UserId": "AIDAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/victor-cli"
}
```
🎉 If you see your account number — you're connected!

---

## 👤 PART 3 — NAMED PROFILES (THE PRO WAY TO WORK)

### 3.1 The Problem With One Set of Keys
In real DevOps you'll touch multiple accounts (dev / staging / prod). Overwriting `aws configure` each time is messy and dangerous — imagine running a `terminate-instances` against PROD because you forgot which keys were active! 😱

### 3.2 The Solution: Profiles
```bash
aws configure --profile dev
aws configure --profile staging
aws configure --profile prod
```
Each profile gets its own section in `~/.aws/credentials` and `~/.aws/config`:
```ini
[dev]
aws_access_key_id = AKIA...
aws_secret_access_key = abcd...

[prod]
aws_access_key_id = AKIA...
aws_secret_access_key = wxyz...
```

### 3.3 Using Profiles
**Option A — flag per command:**
```bash
aws s3 ls --profile dev
aws ec2 describe-instances --profile prod
```

**Option B — environment variable (better for a whole session):**
```bash
export AWS_PROFILE=dev
aws s3 ls          # now uses dev automatically
aws ec2 describe-instances
```
> ⚠️ The env variable wins over the `[default]` profile. To switch: `export AWS_PROFILE=prod`

**Option C — check which identity is active (lifesaver before destructive commands):**
```bash
aws sts get-caller-identity --profile prod
```

---

## 📦 PART 4 — CORE SERVICE COMMANDS (WITH DEEP EXPLANATIONS)

### 4.1 Amazon S3 — Storage

**Concept:** S3 stores objects (files) inside buckets (folders at the root level). Bucket names are **globally unique** across ALL AWS accounts in the world.

#### High-level commands (`aws s3`) — for moving files around
```bash
aws s3 ls                              # list ALL your buckets
aws s3 ls s3://vicks-devops-s3/        # list files INSIDE a bucket
aws s3 ls s3://vicks-devops-s3/logs/   # list a "folder" prefix inside bucket

aws s3 cp report.csv s3://vicks-devops-s3/           # upload one file
aws s3 cp s3://vicks-devops-s3/report.csv ./         # download one file

aws s3 sync ./my-website s3://vicks-devops-s3/       # ⭐ sync whole folder (only changed files)
aws s3 rm s3://vicks-devops-s3/old-file.txt          # delete a file
aws s3 rm s3://vicks-devops-s3/ --recursive          # delete EVERYTHING in bucket (careful!)
```
> 💡 **`sync` is the star command** — it compares local vs remote and only uploads new/changed files. This is exactly how people deploy static websites to S3 + CloudFront. Change one HTML file locally? `aws s3 sync` uploads just that file.

#### Low-level commands (`aws s3api`) — for bucket configuration
```bash
aws s3api create-bucket --bucket vicks-new-bucket --region us-east-1
# Note: for regions OTHER than us-east-1 you need:
aws s3api create-bucket --bucket vicks-new-bucket --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

aws s3api delete-bucket --bucket vicks-new-bucket
# ⚠️ Bucket must be EMPTY first — delete objects first with s3 rm --recursive

aws s3api get-bucket-policy --bucket vicks-devops-s3
aws s3api put-bucket-policy --bucket vicks-devops-s3 --policy file://policy.json
aws s3api delete-bucket-policy --bucket vicks-devops-s3   # escape hatch if locked out!
```

**Why two command families?** `aws s3` = file operations (cp, mv, sync, rm). `aws s3api` = bucket admin (policies, versioning, encryption, website config). Same service, different abstraction level.

---

### 4.2 Amazon EC2 — Virtual Servers

**Concept:** EC2 = rent virtual computers. You specify an AMI (pre-baked OS image), instance type (CPU/RAM size), key pair (SSH access), security group (firewall), and subnet (network placement).

```bash
# READ first — always inspect before you act
aws ec2 describe-instances                          # everything (huge JSON!)
aws ec2 describe-instances --instance-ids i-0a1b2c3d

# CREATE — launch an Ubuntu instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --count 1 \
  --instance-type t3.micro \
  --key-name devops_key \
  --security-group-ids sg-0abc123 \
  --subnet-id subnet-0def456 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=victor-web}]'

# CONTROL lifecycle
aws ec2 stop-instances --instance-ids i-0a1b2c3d     # pause (EBS keeps data, no charge for instance)
aws ec2 start-instances --instance-ids i-0a1b2c3d    # resume
aws ec2 reboot-instances --instance-ids i-0a1b2c3d
aws ec2 terminate-instances --instance-ids i-0a1b2c3d # 💀 DELETE permanently
```

> 🚨 **stop vs terminate:** `stop` = pausing (disk survives, can restart). `terminate` = destruction. Data on instance-store volumes is LOST on terminate; EBS root volumes are deleted by default too (unless you set `DeleteOnTermination=false`).

**Handy extras:**
```bash
aws ec2 describe-key-pairs                # list your SSH keys
aws ec2 describe-images --owners amazon --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"  # find AMIs
```

---

### 4.3 VPC & Security Groups — Networking

**Concept:** A Security Group is a **virtual firewall attached to instances**. Rules are ALLOW-only (no deny rules), and they are STATEFUL (if inbound 80 is allowed, the response flows out automatically).

```bash
aws ec2 describe-vpcs               # list VPCs
aws ec2 describe-subnets            # list subnets
aws ec2 describe-security-groups    # list security groups

# Allow inbound HTTP (port 80) from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id sg-0abc123 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Allow SSH only from YOUR IP (much safer!)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0abc123 \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s ifconfig.me)/32

# Remove a rule
aws ec2 revoke-security-group-ingress \
  --group-id sg-0abc123 --protocol tcp --port 22 --cidr 0.0.0.0/0
```

> 💡 Notice `$(curl -s ifconfig.me)` — CLI lets you mix Linux tools with AWS commands. This inserts your current public IP automatically.

---

### 4.4 IAM — Identity & Access

**Concept:** IAM controls WHO can do WHAT. Users (people), Roles (machines/services), Policies (permission documents written in JSON).

```bash
aws iam list-users                                  # list all users
aws iam list-attached-user-policies --user-name victor-cli   # what can a user do?
aws iam get-user                                    # info about current identity

aws iam create-user --user-name john-devops         # create user

aws iam attach-user-policy \
  --user-name john-devops \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Give the user CLI access (creates access keys)
aws iam create-access-key --user-name john-devops
```

**Understanding ARNs** (you'll see them everywhere):
```
arn:aws:iam::123456789012:user/john-devops
└─┬─┘ └┬┘ └┬┘ └──────┬──────┘ └──────┬──────┘
  arn  svc region   account-id      resource
```
ARNs are AWS's universal "address" for any resource.

---

### 4.5 Other Services Worth Knowing Early

```bash
# CloudWatch — monitoring/logs
aws logs tail /aws/lambda/my-function --follow      # live-tail Lambda logs 🔥

# Lambda — serverless functions
aws lambda list-functions
aws lambda invoke --function-name my-fn out.json    # run it, save response to file
cat out.json

# RDS — databases
aws rds describe-db-instances

# DynamoDB
aws dynamodb list-tables
aws dynamodb scan --table-name users

# CloudFormation — infrastructure as code
aws cloudformation describe-stacks
aws cloudformation deploy --template-file vpc.yaml --stack-name my-vpc
```

---

## 🎯 PART 5 — THE PRO TECHNIQUES (THIS IS WHERE YOU LEVEL UP)

### 5.1 Output Formats
Commands return JSON by default. Three formats, three use cases:

```bash
aws ec2 describe-instances --output json    # default; full detail, programmatic
aws ec2 describe-instances --output table   # ⭐ human-readable ASCII tables
aws ec2 describe-instances --output text    # flat lines; best for shell scripting/grep
```

Set your favorite once in `aws configure` — most pros pick `json` or `table`.

### 5.2 `--query` — Extract Only What You Need (JMESPath)
Raw JSON from `describe-instances` can be 300+ lines. JMESPath is a query language to slice it:

```bash
# Just IDs + IPs of running instances, as a table
aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId, PublicIpAddress, State.Name]" \
  --output table
```
Reading the JMESPath syntax:
- `Reservations[*]` → for every reservation (EC2 groups instances into reservations)
- `.Instances[*]` → for every instance inside
- `.[InstanceId, PublicIpAddress]` → pull just these fields

More examples you'll actually use:
```bash
# All bucket names, one per line
aws s3api list-buckets --query "Buckets[*].Name" --output text

# All VPC IDs + CIDR blocks
aws ec2 describe-vpcs --query "Vpcs[*].[VpcId, CidrBlock]" --output table

# Find my key pairs
aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output text
```

### 5.3 `--filters` — Server-Side Filtering
`--query` filters **after** AWS sends data. `--filters` tells AWS to filter **before** sending — faster, cheaper:

```bash
# Only RUNNING instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"

# Instances tagged with a specific Name
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=victor-web"

# Only t3.micro instances
aws ec2 describe-instances \
  --filters "Name=instance-type,Values=t3.micro"

# Combine filters (AND logic)
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=instance-type,Values=t3.micro"
```

**Filter syntax cheat:** `"Name=<field>,Values=<v1>,<v2>"` — comma = OR within a filter, multiple filters = AND.

### 5.4 Chain With Linux Tools (`jq`, `grep`, `awk`)
The CLI plays beautifully with standard Linux tools:

```bash
# Count running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "length(Reservations[*].Instances[*])"

# Extract one value for a script
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=victor-web" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)
echo $INSTANCE_ID
aws ec2 stop-instances --instance-ids $INSTANCE_ID
```

`jq` (install separately) is the JSON power tool:
```bash
aws ec2 describe-instances | jq '.Reservations[].Instances[] | {id: .InstanceId, ip: .PublicIpAddress, state: .State.Name}'
```

### 5.5 Dry Runs & Pagination
- **Test without executing:** many destructive commands accept `--dry-run`. It validates permissions and parameters, then reports "DryRunOperation" if you'd have succeeded:
```bash
aws ec2 terminate-instances --instance-ids i-0abc --dry-run
```
- **Large result sets:** AWS paginates (1000 items/page). CLI auto-handles it — but in scripts use `--max-results` and `--starting-token` if needed.

---

## 🆘 PART 6 — TROUBLESHOOTING (YOU WILL HIT THESE)

| Error | Meaning | Fix |
|---|---|---|
| `Unable to locate credentials` | No keys configured | Run `aws configure` or check `AWS_PROFILE` |
| `InvalidClientTokenId` | Wrong/bad access key | Re-check `~/.aws/credentials` |
| `SignatureDoesNotMatch` | Secret key typo | Re-create keys; secret has no extra spaces |
| `AccessDenied` / `UnauthorizedOperation` | IAM permission missing | Attach needed policy; check with `aws sts get-caller-identity` |
| `UnauthorizedOperation ... explicitly denied` | Explicit DENY in policy/scp | Check SCPs (in Organizations) — only admin can fix |
| `NoSuchBucket` | Bucket name wrong or wrong region | Bucket names are global; check spelling |
| `BucketAlreadyExists` | Name taken by ANYONE in the world | Choose unique name (add your name/ID) |
| `InvalidAMIID.NotFound` | AMI doesn't exist in your region | AMIs are region-specific! Find the right one per region |
| `DependencyViolation` | Resource has attachments | Delete dependent resources first (e.g., instances in a subnet) |

**The universal debugger:** add `--debug` to any command to see the full request/response — heavy output but shows exactly what was sent:
```bash
aws s3 ls --debug 2>&1 | less
```

**Stuck on `--help`?** Every command documents itself:
```bash
aws s3 cp --help          # parameters for ONE action
aws s3 --help             # all actions in a service
aws --help                # all services
```

---

## 🏋️ PART 7 — HANDS-ON PRACTICE LABS (DO THESE!)

> 💰 **Cost control:** everything below fits in AWS Free Tier (t3.micro 750 hrs/month, S3 5GB). ALWAYS `terminate`/`delete` at the end.

### Lab 1 — Identity & Buckets (Day 1)
1. `aws sts get-caller-identity` → confirm connection
2. `aws s3 mb s3://victor-cli-lab-<youraccountid>` → create bucket
3. Create a text file locally, `aws s3 cp` it up, `aws s3 ls` to verify, download it back, compare with `diff`
4. `aws s3 rb s3://victor-cli-lab-<id> --force` → delete everything

### Lab 2 — Launch & Inspect an EC2 (Day 2)
1. `aws ec2 describe-key-pairs` → note a key name (create one in console if none)
2. `aws ec2 describe-subnets` → grab a subnet ID
3. `aws ec2 describe-security-groups` → grab a SG ID
4. `aws ec2 run-instances` to launch a t3.micro with a Name tag `victor-lab`
5. `aws ec2 describe-instances --filters "Name=tag:Name,Values=victor-lab" --query ...` → find its IP
6. **SSH into it**, then `stop` it, then `terminate` it

### Lab 3 — Profiles & Query Mastery (Day 3)
1. Create a `--profile lab` with a fresh IAM user (read-only policy)
2. Try `aws ec2 terminate-instances` with that profile → expect AccessDenied
3. Extract all running instance IDs into a variable and loop over them printing states
4. Use `jq` to pretty-print a describe-instances response

### Lab 4 — Mini Real-World Project (Weekend)
**Deploy a static website to S3 via CLI:**
```bash
BUCKET=victor-portfolio-$RANDOM
aws s3 mb s3://$BUCKET
aws s3 website s3://$BUCKET --index-document index.html   # enable static hosting
# create index.html locally, then:
aws s3 sync . s3://$BUCKET --acl public-read
aws s3api get-bucket-website --bucket $BUCKET   # get the endpoint URL
curl http://$BUCKET.s3-website-us-east-1.amazonaws.com   # visit your site!
```

---

## 📋 PART 8 — FINAL CHEAT SHEET (PIN THIS)

```
PATTERN      aws <service> <action> [flags]
IDENTITY     aws sts get-caller-identity
PROFILES     aws configure --profile <name>  |  export AWS_PROFILE=<name>
READ         describe-*  |  list-*
WRITE        create-* / run-* / put-*
DESTROY      delete-* / terminate-* / rm
OUTPUT       --output json|table|text
EXTRACT      --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress]"
FILTER       --filters "Name=instance-state-name,Values=running"
HELP         aws <service> <action> --help
DEBUG        --debug
TEST FIRST   --dry-run
```

### Golden Rules of a CLI Pro:
1. ✅ **Always `describe` before you `delete`** — confirm the target exists and is the right one.
2. ✅ **Check identity first on shared machines:** `aws sts get-caller-identity`.
3. ✅ **Use profiles, never root keys.**
4. ✅ **Tag everything** (`--tag-specifications`) so you can find and filter resources later.
5. ✅ **Clean up labs the same day** — free tier is only free if you stop things.
6. ❌ **Never put credentials in scripts or git** — use profiles, env vars, or IAM Roles.

---
*Next step after this: learn the same patterns in **boto3 (Python SDK)** — identical service/action/parameter logic, so this note transfers directly. Then Terraform will feel like a natural upgrade path.*
