# Detailed Note: Logging into an AWS EC2 Instance from Ubuntu (WSL)

**Date:** 24 September 2026
**Target instance:** 54.172.67.47
**Private key:** devops_key.pem
**Local environment:** Ubuntu running inside Windows (WSL)

---

## 1. Background: What Is Actually Happening?

**SSH (Secure Shell)** is a protocol that lets you open a secure, encrypted terminal session on a remote machine over a network. When you "log into" an EC2 instance, your WSL terminal becomes a window into the remote Linux server — every command you type after login runs *on the server*, not on your laptop.

Authentication works with a **key pair**:

| File | Where it lives | What it does |
|---|---|---|
| **Private key** (`devops_key.pem`) | Stays on YOUR computer | Proves your identity. Never share it. |
| **Public key** | Already installed on the EC2 instance by AWS | Verifies that you hold the matching private key |

When you connect, SSH proves to the server that you own the private key — no password is needed.

---

## 2. Prerequisites (Check These Before You Start)

Most login failures happen because one of these is missing:

1. **The EC2 instance is running.** In the AWS Console → EC2 → Instances, the instance state must be `running`. A stopped instance has no running SSH service.
2. **Port 22 is open.** Check the instance's **Security Group** → Inbound rules must allow **SSH (port 22)** from your IP (or `0.0.0.0/0`).
3. **You have the correct private key.** The `.pem` file must be the one whose public key was injected into the instance at launch. A key from a *different* instance will always fail with `Permission denied (publickey)`.
4. **You know the correct username.** It depends on the AMI (Amazon Machine Image) used to launch the instance:
   - Ubuntu AMIs → `ubuntu`
   - Amazon Linux AMIs → `ec2-user`
   - RHEL AMIs → `ec2-user` or `root`
   - Debian AMIs → `admin` or `root`
   - CentOS AMIs → `centos`

> **Note:** Public IPs change when an instance is stopped and restarted (unless you use an Elastic IP). If the IP in this note no longer works, get the current IP from the AWS Console.

---

## 3. Step-by-Step Login Procedure

### Step 1: Verify That the Key Exists

```bash
ls -l /mnt/c/Users/hp/Downloads/devops_key.pem
```

**What it does:** `ls` (list files) with the `-l` flag shows detailed file information. The path `/mnt/c/...` is how WSL sees your Windows C: drive.

**Why we run it:** Before anything else, confirm Ubuntu can actually see the key file.

**Expected output:**
```
-rw-r--r-- 1 victorusen23 victorusen23 1675 Sep 24 10:00 devops_key.pem
```

If you see file details like this, the key is there. If you see `No such file or directory`, check the path and filename.

### Step 2: Create an SSH Directory

```bash
mkdir -p ~/.ssh
```

**What it does:** `mkdir` (make directory) creates the `.ssh` folder in your home directory. The `-p` flag means "don't complain if it already exists."

**Why we run it:** `~/.ssh` is the standard, secure location for SSH keys and configuration on Linux. `~` is shorthand for your home directory (`/home/victorusen23`).

### Step 3: Copy the Key into the SSH Folder

```bash
cp /mnt/c/Users/hp/Downloads/devops_key.pem ~/.ssh/
```

**What it does:** `cp` (copy) duplicates the key from Windows storage into Linux storage.

**Why we run it:** A key used directly from the Windows drive (`/mnt/c/...`) inherits Windows-style permissions, which SSH on Linux considers "too open" and will reject. Storing the key inside the Linux filesystem gives you full control over its permissions.

### Step 4: Restrict File Permissions

```bash
chmod 400 ~/.ssh/devops_key.pem
```

**What it does:** `chmod` (change mode) sets who can do what with the file.

**Permission value `400` means:**

| Who | Permission |
|---|---|
| Owner (you) | Read only |
| Group | No access |
| Others | No access |

**Why we run it:** SSH refuses to use a private key that anyone else can read. If permissions are too open, you get:

```
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions 0644 for '/home/victorusen23/.ssh/devops_key.pem' are too open.
```

### Step 5: Confirm the Permissions

```bash
ls -l ~/.ssh/devops_key.pem
```

**Expected output:**
```
-r-------- 1 victorusen23 victorusen23 1675 Sep 24 10:00 devops_key.pem
```

The important part is `-r--------`: only the owner can read it. The key is secure.

### Step 6: Connect to the EC2 Instance

```bash
ssh -i ~/.ssh/devops_key.pem ubuntu@54.172.67.47
```

**Breaking down every part of this command:**

| Part | Meaning |
|---|---|
| `ssh` | Start a Secure Shell connection — "open a secure remote terminal session" |
| `-i` | Identity file — "use this private key for authentication" (without it, SSH tries default keys and may fail) |
| `~/.ssh/devops_key.pem` | Path to your private key |
| `ubuntu` | The username on the EC2 server |
| `54.172.67.47` | The public IP address of the EC2 instance |

**Full meaning:** *"Connect securely to server 54.172.67.47 as user `ubuntu`, proving my identity with the private key `devops_key.pem`."*

### Step 7: First-Connection Prompt

On your very first connection to this server, you will see:

```
The authenticity of host '54.172.67.47' can't be established.
ECDSA key fingerprint is SHA256:aBcD1234...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**Why this appears:** Your computer has never connected to this server before, so it cannot verify the server's identity. SSH is asking you to confirm you trust it.

**What to do:** Type `yes` and press Enter. The server's fingerprint is saved to `~/.ssh/known_hosts`, and you won't be asked again unless the server changes.

> ⚠️ **Security note:** If you are asked this question *again later* for a server you've connected to before, it can mean the server was rebuilt or someone is intercepting the connection (a "man-in-the-middle" attempt). Verify before typing `yes`.

### Step 8: Successful Login

If everything works, you'll see something like:

```
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1051-aws x86_64)

ubuntu@ip-172-31-10-25:~$
```

**What this means:**

| Signal | Meaning |
|---|---|
| ✅ `Welcome to Ubuntu 22.04` | Key accepted |
| ✅ `ubuntu@ip-172-31-10-25` | Authentication successful; you are logged in as `ubuntu` on the server (the `ip-172-31-...` part is the server's **private** internal IP, which is normal) |
| ✅ `~` | You are in your home directory on the server |
| ✅ `$` | A regular user prompt (`#` would mean the root superuser) |

**From this point on, every command you type runs on the EC2 server** — not on your local machine.

---

## 4. Logging Out

When finished, end the session cleanly with any of these:

```bash
exit
```
```bash
logout
```
Or press **Ctrl + D**

This closes the SSH session. Your local WSL terminal remains open.

---

## 5. Troubleshooting: Common Errors and Fixes

### Error 1: `No such file or directory`

**Meaning:** SSH cannot find the key file.
**Fix:** Verify the path and filename:
```bash
ls -l ~/.ssh/devops_key.pem
```

### Error 2: `WARNING: UNPROTECTED PRIVATE KEY FILE!`

**Meaning:** The key permissions are too open.
**Fix:**
```bash
chmod 400 ~/.ssh/devops_key.pem
```

### Error 3: `Permission denied (publickey)`

**Meaning:** The server rejected your key. Possible causes:
- Wrong key file (key does not match this instance)
- Wrong username for the AMI
- The public key was never installed on the server
- You are connecting to the wrong IP address

**Fix:** Try the common AMI usernames:
```bash
ssh -i ~/.ssh/devops_key.pem ubuntu@54.172.67.47
ssh -i ~/.ssh/devops_key.pem ec2-user@54.172.67.47
ssh -i ~/.ssh/devops_key.pem admin@54.172.67.47
```

Still failing? Debug with verbose output — it shows exactly where authentication breaks:
```bash
ssh -v -i ~/.ssh/devops_key.pem ubuntu@54.172.67.47
```

### Error 4: `Connection timed out`

**Meaning:** No response from the server at all — the network path is blocked.
**Fix — check in this order:**
1. Is the instance **running**? (AWS Console → EC2 → Instances)
2. Is the **Security Group** inbound rule allowing SSH (port 22) from your IP?
3. Is the **public IP** still correct? (IPs change after stop/start unless Elastic IP)
4. Is your **local network or firewall** blocking outbound SSH?

### Error 5: `REMOTE HOST IDENTIFICATION HAS CHANGED!`

**Meaning:** The server's fingerprint no longer matches what was saved in `~/.ssh/known_hosts`. Usually happens when the instance was stopped/started with a new IP, or rebuilt.
**Fix:** Remove the old entry, then reconnect and accept the new fingerprint:
```bash
ssh-keygen -R 54.172.67.47
```

---

## 6. Quick Reference: Complete Login Sequence

```bash
# 1. Create SSH folder (if it doesn't exist)
mkdir -p ~/.ssh

# 2. Copy the key into it
cp /mnt/c/Users/hp/Downloads/devops_key.pem ~/.ssh/

# 3. Lock down permissions
chmod 400 ~/.ssh/devops_key.pem

# 4. Verify
ls -l ~/.ssh/devops_key.pem

# 5. Connect
ssh -i ~/.ssh/devops_key.pem ubuntu@54.172.67.47
```

---

## 7. Security Reminders

1. **Never share your private key** (`devops_key.pem`) or commit it to Git. Anyone holding it can log into your server.
2. **Never loosen permissions** (`chmod 777`) on a private key to "make it work" — SSH will still reject it, and you've created a security hole.
3. **Stop or terminate instances you aren't using** to avoid AWS charges — but remember the public IP will change on restart.
4. Keep the original `.pem` backup somewhere safe (e.g., an encrypted USB or password manager), in case the copy in `~/.ssh` is lost.

---

*End of note. This document explains both the **how** and the **why** of each step, so future login issues can be diagnosed from first principles.*
