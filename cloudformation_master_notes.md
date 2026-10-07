# ☁️ AWS CloudFormation — Master Notes (Zero to Hero)

> **Infrastructure as Code made simple.** One file in, one entire environment out — and one command to clean it all up.

![AWS](https://img.shields.io/badge/AWS-CloudFormation-FF9900?logo=amazon-aws&logoColor=white)
![Level](https://img.shields.io/badge/Level-Beginner%20to%20Hero-brightgreen)
![Format](https://img.shields.io/badge/Format-YAML%20%7C%20Markdown-blue)

---

## 🧠 What Is CloudFormation?

**CloudFormation** is AWS's *Infrastructure as Code (IaC)* service.

Instead of clicking around the console to build resources, you write a **text file** (YAML or JSON) describing your infrastructure — and AWS builds it for you, every time, exactly the same way.

> 🍳 **The kitchen analogy:**
>
> | CloudFormation term | Kitchen term |
> |---|---|
> | 📝 **Template** | The *recipe* (code, stored in Git) |
> | 🏗️ **Stack** | The *meal* (your live resources) |
> | 👀 **Change Set** | *Taste before serving* (preview changes) |
> | 🌪️ **Drift** | Someone *changed the recipe while cooking* (manual console edits) |

---

## 📚 Part 1: Core Concepts

### The 4 Key Terms

| Term | What it actually means |
|---|---|
| 📝 **Template** | A YAML/JSON file describing **what** to create and **how** to configure it. This is your code — keep it in Git. |
| 🏗️ **Stack** | The live resources built from a template. **Update the stack** = resources change. **Delete the stack** = *everything inside is deleted*. Cleanup becomes *one command* instead of twenty. |
| 👀 **Change Set** | A **preview** of exactly what AWS will create, modify, or **delete** before you apply an update. No surprises. |
| 🌪️ **Drift Detection** | Spots when someone **manually edits** a resource in the console — so you know reality no longer matches your template. |

---

## 🧩 Part 2: Anatomy of a Template

A template can have up to **9 sections**. Only `Resources` is required.

```yaml
AWSTemplateFormatVersion: "2010-09-09"   # File format version (fixed value)
Description: What this template builds    # Human-readable summary

Parameters:    # 🎛️ Inputs passed at deploy time (env name, instance type)
Mappings:      # 🗺️ Static lookup tables (e.g., AMIs per region)
Conditions:    # 🔀 If-logic — create X only when Y is true
Transform:     # ✨ Macros that expand the template (e.g., AWS SAM)

Resources:     # ⚠️ THE ONLY REQUIRED SECTION — your infrastructure
  MyResource:
    Type: AWS::Service::ResourceType
    Properties:
      Property1: Value

Outputs:       # 📤 Values printed after deployment (URLs, IPs, IDs)
```

> 💡 **Golden rule:** put anything that changes between environments (dev / staging / prod) into **Parameters**. Keep `Resources` generic and reusable.

---

## 🛠️ Part 3: The 5 Functions You'll Use Daily

| Function | Say it as | Example |
|---|---|---|
| `!Ref` | *"Give me its ID"* | `!Ref WebServerSecurityGroup` |
| `!GetAtt` | *"Give me its property"* | `!GetAtt WebServerInstance.PublicIp` |
| `!Sub` | *"Fill in this blank"* | `!Sub "${EnvironmentName}-web-server"` |
| `!Join` | *"Glue strings together"* | `!Join [ "-", [ "prod", "web" ] ]` → `prod-web` |
| `!FindInMap` | *"Look it up in the table"* | `!FindInMap [ RegionMap, !Ref AWS::Region, AMI ]` |

---

## 🚀 Part 4: Hands-On Project — Web Server Stack

**Goal:** deploy a complete web server with one command:

- [x] 🔒 Security Group (SSH port 22 + HTTP port 80)
- [x] 💻 EC2 instance (latest Amazon Linux 2023 AMI — resolved automatically)
- [x] 📜 User Data script that installs Apache and serves a custom page
- [x] 🔗 Stack Outputs showing the live URL and public IP

### Step 1 — Create the template (`webserver.yaml`)

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: Production-ready single-instance Apache web server

Parameters:
  EnvironmentName:
    Type: String
    Default: dev
    AllowedValues: [dev, staging, prod]
    Description: Deployment environment label

  InstanceType:
    Type: String
    Default: t2.micro
    AllowedValues: [t2.micro, t3.micro, t3.small]
    Description: EC2 compute instance type

Resources:
  # 🔒 1. Security Group — the firewall for the server
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable SSH and HTTP ingress traffic
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0        # 🌐 HTTP from anywhere
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0        # 🔑 SSH from anywhere
      Tags:
        - Key: Name
          Value: !Sub "${EnvironmentName}-web-sg"

  # 💻 2. EC2 Instance — the web server itself
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      # 🔄 Always fetches the LATEST Amazon Linux 2023 AMI for the region
      ImageId: "{{resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64}}"
      SecurityGroups:
        - !Ref WebServerSecurityGroup
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          dnf update -y
          dnf install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Welcome to CloudFormation Web Server [${EnvironmentName}]</h1>" > /var/www/html/index.html
      Tags:
        - Key: Name
          Value: !Sub "${EnvironmentName}-web-server"

Outputs:
  WebsiteURL:
    Description: 🌍 HTTP URL for the web server
    Value: !Sub "http://${WebServerInstance.PublicDnsName}"

  PublicIP:
    Description: 🌐 Public IP of the web server
    Value: !GetAtt WebServerInstance.PublicIp
```

### Step 2 — Deploy 🚀

Run in the same folder as `webserver.yaml`:

```bash
# ✅ Always validate first (catches syntax errors early)
aws cloudformation validate-template --template-body file://webserver.yaml

# 🚀 Deploy the stack
aws cloudformation deploy \
  --template-file webserver.yaml \
  --stack-name my-web-server-stack \
  --parameter-overrides EnvironmentName=dev InstanceType=t2.micro
```

### Step 3 — Verify 🔍

```bash
# 🔗 Get the live website URL and IP
aws cloudformation describe-stacks \
  --stack-name my-web-server-stack \
  --query "Stacks[0].Outputs" \
  --output table

# ⏱️ Watch resources being created in real time
aws cloudformation describe-stack-events \
  --stack-name my-web-server-stack \
  --query "StackEvents[*].[LogicalResourceId, ResourceType, ResourceStatus]" \
  --output table
```

Open the **WebsiteURL** in your browser to see the Apache page. 🎉

### Step 4 — Cleanup 🧹

```bash
# ⚠️ ONE command deletes EVERYTHING
aws cloudformation delete-stack --stack-name my-web-server-stack
```

---

## 🏆 Part 5: Production Best Practices

| # | Practice | Why it matters |
|---|---|---|
| 1 | 🔐 **Never hardcode secrets or AMI IDs** | AMIs → use `{{resolve:ssm:...}}` · Secrets → use `{{resolve:secretsmanager:...}}` |
| 2 | 🧱 **Split big projects into nested stacks** | e.g., one stack for VPC/network, another for the app — like functions in code: reusable, easier to debug |
| 3 | 🛡️ **Protect important data** with `DeletionPolicy: Retain` | On S3 buckets/databases — deleting the stack won't delete your data |
| 4 | ✅ **Always validate in CI/CD** before deploying | `aws cloudformation validate-template --template-body file://webserver.yaml` |
| 5 | 👀 **Preview changes with change sets** before updating production | No surprise deletions |

---

## 🎯 Quick Memory Aids

```text
📝 Template  = the recipe              🏗️ Stack  = the meal
👀 ChangeSet = taste before serving    🌪️ Drift  = recipe changed mid-cooking
!Ref    = "give me its ID"             !GetAtt  = "give me its property"
!Sub    = "fill in this blank"         !Join    = "glue strings together"
```

---

> ✍️ *Notes compiled for learning purposes — pair with hands-on practice for best results.*
