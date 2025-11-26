# Deploy AWS EC2 Infrastructure with Terraform: A Complete Step-by-Step Guide

**A practical guide for aspiring DevOps engineers to automate cloud infrastructure deployment**

---

## Introduction

Infrastructure as Code (IaC) is transforming how we deploy and manage cloud resources. This comprehensive guide walks you through deploying a complete AWS infrastructure using Terraform, from creating a custom VPC to launching a web server accessible from the internet.

By the end of this tutorial, you'll have hands-on experience with:
- Creating AWS networking infrastructure (VPC, subnets, gateways)
- Writing Terraform configuration files
- Managing infrastructure state
- Deploying and accessing an EC2 instance
- Cleaning up cloud resources

### What We're Building

We'll create a production-ready infrastructure that includes:
- **VPC (Virtual Private Cloud)** with CIDR block 10.0.0.0/16
- **Public subnet** (10.0.1.0/24) for internet-facing resources
- **Private subnet** (10.0.2.0/24) for isolated resources
- **Internet Gateway** for public internet connectivity
- **Route tables** with proper associations
- **Security groups** allowing HTTP and SSH access
- **EC2 instance** running Ubuntu 20.04 with Nginx web server

### Prerequisites

Before starting, ensure you have:
- AWS account (free tier works perfectly)
- Basic understanding of Linux commands
- Familiarity with cloud computing concepts
- Text editor (VS Code recommended)

### Required Tools

- **Terraform** (version 1.0 or higher)
- **AWS CLI** (version 2.0 or higher)
- **SSH client** (built into Linux/macOS, PuTTY for Windows)

### Time Required

45-60 minutes for complete deployment and verification.

### Cost

All resources used are free-tier eligible. Estimated cost: $0-2/month.

---

## Part 1: Understanding the Architecture

Before writing any code, it's crucial to understand what we're building.

### VPC (Virtual Private Cloud)

A VPC is your isolated network environment in AWS. Think of it as your private data center in the cloud where you have complete control over:
- IP address ranges
- Subnets
- Route tables
- Network gateways

Our VPC uses CIDR block **10.0.0.0/16**, providing 65,536 IP addresses.

### Subnets

Subnets divide your VPC into smaller network segments.

**Public Subnet (10.0.1.0/24):**
- Contains 256 IP addresses (AWS reserves 5)
- Resources automatically receive public IP addresses
- Has direct internet access through Internet Gateway
- Hosts our web server

**Private Subnet (10.0.2.0/24):**
- Contains 256 IP addresses (AWS reserves 5)
- Resources use private IP addresses only
- No direct internet access (perfect for databases)
- Communicates with public subnet within VPC

### Internet Gateway

The Internet Gateway serves as the door between your VPC and the internet. It:
- Enables communication with the internet
- Performs network address translation (NAT)
- Provides high availability automatically

### Route Tables

Route tables control network traffic flow. Our public route table includes:
- Local route for internal VPC communication (automatic)
- Default route (0.0.0.0/0) pointing to Internet Gateway

### Security Groups

Security groups act as virtual firewalls for your instances. Our configuration allows:

**Inbound (Incoming Traffic):**
- Port 22 (SSH) for remote access
- Port 80 (HTTP) for web traffic
- Port 443 (HTTPS) for secure web traffic

**Outbound (Outgoing Traffic):**
- All ports and protocols (allows instance to reach internet)

### EC2 Instance

Our virtual server specifications:
- **AMI:** Ubuntu 20.04 LTS (latest)
- **Instance Type:** t2.micro (1 vCPU, 1GB RAM, free tier eligible)
- **Storage:** 8GB EBS volume
- **Software:** Nginx web server (auto-installed)

### Traffic Flow Diagram

```
Internet → Internet Gateway → Route Table → Public Subnet → Security Group → EC2 Instance
```

1. User enters instance IP in browser
2. Request hits Internet Gateway
3. Route table directs to public subnet
4. Security group validates port 80 is allowed
5. Request reaches EC2 instance
6. Nginx serves the webpage

---

## Part 2: Environment Setup

Let's prepare your development environment.

### Step 1: Verify Terraform Installation

Open your terminal and check Terraform version:

```bash
terraform --version
```

**Expected output:**
```
Terraform v1.14.0
on linux_amd64
```

**If not installed:**
- **macOS:** `brew install terraform`
- **Ubuntu/Debian:** `sudo apt-get install terraform`
- **Windows:** Download from [terraform.io](https://www.terraform.io/downloads)

### Step 2: Verify AWS CLI Installation

Check AWS CLI version:

```bash
aws --version
```

**Expected output:**
```
aws-cli/2.32.5 Python/3.13.9 Linux/6.8.0-1030-azure
```

**If not installed:** Follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Step 3: Configure AWS Credentials

You need programmatic access to AWS. Here's how to set it up:

#### Getting AWS Credentials

1. Log into AWS Console
2. Navigate to **IAM** → **Users**
3. Select your user (or create a new one)
4. Click **Security credentials** tab
5. Click **Create access key**
6. Choose **Command Line Interface (CLI)**
7. Download or copy the credentials

#### Configure CLI

Run the configuration command:

```bash
aws configure
```

Enter your information:
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Important:** Never commit these credentials to Git or share them publicly.

### Step 4: Verify Authentication

Confirm AWS CLI can communicate with your account:

```bash
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDATLP2HDKP47EJ246D4",
    "Account": "230842374815",
    "Arn": "arn:aws:iam::230842374815:user/YourUsername"
}
```

If you see your account details, you're ready to proceed!

---

## Part 3: SSH Key Generation

We need SSH keys to securely access our EC2 instance.

### Generate Key Pair

Run this command to create a 4096-bit RSA key pair:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-aws-key -N ""
```

**Command breakdown:**
- `-t rsa`: Use RSA encryption algorithm
- `-b 4096`: Key size (more secure than default 2048)
- `-f ~/.ssh/terraform-aws-key`: File location and name
- `-N ""`: Empty passphrase (for automation)

**Output:**
```
Generating public/private rsa key pair.
Created directory '/home/user/.ssh'.
Your identification has been saved in /home/user/.ssh/terraform-aws-key
Your public key has been saved in /home/user/.ssh/terraform-aws-key.pub
The key fingerprint is:
SHA256:EWm8hkugUQeIsQ+AINrR4iXK6vIPe0xFlq/WfkYblDA user@hostname
```

### Verify Keys Were Created

```bash
ls -la ~/.ssh/terraform-aws-key*
```

**You should see:**
```
-rw------- 1 user user 3401 Nov 26 15:23 terraform-aws-key
-rw-r--r-- 1 user user  753 Nov 26 15:23 terraform-aws-key.pub
```

### Set Proper Permissions

Ensure correct permissions on the private key:

```bash
chmod 600 ~/.ssh/terraform-aws-key
```

SSH requires strict permissions or it will refuse to use the key.

---

## Part 4: Project Structure Setup

Organize your project properly from the start.

### Create Project Directory

```bash
mkdir -p ~/terraform-aws-vm
cd ~/terraform-aws-vm
```

### Create Configuration Files

```bash
touch main.tf variables.tf outputs.tf terraform.tfvars
```

### File Purposes

- **main.tf** - All AWS resource definitions
- **variables.tf** - Input variable declarations
- **outputs.tf** - Values to display after deployment
- **terraform.tfvars** - Actual variable values

This modular structure keeps your code organized and maintainable.

---

## Part 5: Writing Terraform Configuration

Now let's create the actual infrastructure code.

### File 1: main.tf

Create `main.tf` with the following content:

```hcl
# Configure Terraform and AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Type        = "Public"
  }
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Type        = "Private"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group
resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server allowing SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-sg"
    Environment = var.environment
  }
}

# Data source to get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

# Create EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  key_name               = aws_key_pair.deployer.key_name

  # User data script to install Nginx
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              
              # Create custom welcome page
              echo "<h1>Welcome to ${var.project_name}</h1>" > /var/www/html/index.html
              echo "<p>Deployed with Terraform on AWS</p>" >> /var/www/html/index.html
              echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              echo "<p>Availability Zone: $(ec2-metadata --availability-zone | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
  }
}
```

**Key Points:**
- `enable_dns_hostnames = true`: Required for instances to get public DNS names
- `map_public_ip_on_launch = true`: Automatically assigns public IPs
- Data source automatically fetches the latest Ubuntu AMI
- User data script runs once when instance first boots
- Security group allows HTTP, HTTPS, and SSH traffic

### File 2: variables.tf

Create `variables.tf`:

```hcl
# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Project Name
variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "terraform-aws-vm"
}

# Environment
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnet CIDR
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Private Subnet CIDR
variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# SSH Public Key Path
variable "public_key_path" {
  description = "Path to the SSH public key for EC2 access"
  type        = string
  default     = "~/.ssh/terraform-aws-key.pub"
}
```

**Why Variables?**
- Makes code reusable across environments
- Centralizes configuration
- Enforces type safety
- Provides clear documentation

### File 3: outputs.tf

Create `outputs.tf`:

```hcl
# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# VPC CIDR Block
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Public Subnet ID
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

# Private Subnet ID
output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# Internet Gateway ID
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Security Group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server.id
}

# EC2 Instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

# EC2 Instance Public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

# EC2 Instance Private IP
output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

# EC2 Instance Public DNS
output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

# SSH Connection Command
output "ssh_connection_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ~/.ssh/terraform-aws-key ubuntu@${aws_instance.web_server.public_ip}"
}

# Web URL
output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}
```

**Output Benefits:**
- Displays critical information after deployment
- Can be queried anytime with `terraform output`
- Used in automation and scripts
- Helps with debugging

### File 4: terraform.tfvars

Create `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "terraform-aws-vm"
environment  = "dev"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
private_subnet_cidr  = "10.0.2.0/24"

# EC2 Configuration
instance_type    = "t2.micro"
public_key_path  = "~/.ssh/terraform-aws-key.pub"
```

**Note:** Terraform automatically loads `terraform.tfvars`. For sensitive data, use environment variables or secret management tools.

---

## Part 6: Terraform Workflow

Now let's deploy the infrastructure!

### Step 1: Initialize Terraform

Initialize the working directory and download providers:

```bash
terraform init
```

**Expected output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installed hashicorp/aws v5.x.x (signed by HashiCorp)

Terraform has been successfully initialized!
```

**What happened:**
- Downloaded AWS provider plugin
- Created `.terraform` directory
- Generated `.terraform.lock.hcl` file

### Step 2: Format Configuration

Ensure consistent code formatting:

```bash
terraform fmt
```

**Output:** Lists any files that were reformatted (or no output if already formatted).

### Step 3: Validate Configuration

Check for syntax errors:

```bash
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

If you see errors, read them carefully - Terraform provides helpful error messages with line numbers.

### Step 4: Create Execution Plan

Preview what Terraform will create:

```bash
terraform plan
```

**Sample output:**
```
Terraform will perform the following actions:

  # aws_instance.web_server will be created
  + resource "aws_instance" "web_server" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + public_ip                    = (known after apply)
      ...
    }

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block                   = "10.0.0.0/16"
      + enable_dns_hostnames         = true
      ...
    }

Plan: 9 to add, 0 to change, 0 to destroy.
```

**Review carefully:**
- 9 resources will be created
- No existing resources will be changed or destroyed
- Symbols: `+` (create), `~` (modify), `-` (destroy)

### Step 5: Apply Configuration

Deploy the infrastructure:

```bash
terraform apply
```

Terraform shows the plan again and asks for confirmation:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type **`yes`** (exactly - not "y" or "YES") and press Enter.

**Deployment Progress:**
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s [id=vpc-0123456789abcdef0]
aws_subnet.public: Creating...
aws_internet_gateway.main: Creating...
aws_subnet.public: Creation complete after 1s [id=subnet-0123456789abcdef0]
...
aws_instance.web_server: Still creating... [10s elapsed]
aws_instance.web_server: Still creating... [20s elapsed]
aws_instance.web_server: Creation complete after 32s [id=i-0123456789abcdef0]

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

instance_public_ip = "54.123.45.67"
ssh_connection_command = "ssh -i ~/.ssh/terraform-aws-key ubuntu@54.123.45.67"
web_url = "http://54.123.45.67"
vpc_id = "vpc-0123456789abcdef0"
...
```

**Save the public IP!** You'll need it to access your instance.

Deployment typically takes 2-3 minutes.

---

## Part 7: Verification and Testing

Let's verify everything works correctly.

### Check AWS Console

1. Log into AWS Console
2. Navigate to **EC2** → **Instances**
3. You should see your instance in "running" state

**Verify:**
- Instance state: Running
- Instance type: t2.micro
- Public IPv4 address matches Terraform output
- VPC and Subnet IDs match outputs

### Navigate to VPC Section

Check **VPC** → **Your VPCs**:
- One VPC with CIDR 10.0.0.0/16
- DNS resolution and hostnames enabled

Check **Subnets**:
- Public subnet: 10.0.1.0/24 in us-east-1a
- Private subnet: 10.0.2.0/24 in us-east-1b

Check **Security Groups**:
- Your security group with SSH, HTTP, HTTPS rules

### SSH Connection Test

Connect to your instance via SSH:

```bash
ssh -i ~/.ssh/terraform-aws-key ubuntu@YOUR_PUBLIC_IP
```

Replace `YOUR_PUBLIC_IP` with your actual instance IP.

**First connection:**
```
The authenticity of host '54.123.45.67' can't be established.
ECDSA key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)?
```

Type `yes` and press Enter.

**Successful connection:**
```
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.15.0-1051-aws x86_64)

ubuntu@ip-10-0-1-123:~$
```

You're now inside your EC2 instance!

### Verify Nginx Installation

Check if Nginx is running:

```bash
sudo systemctl status nginx
```

**Expected output:**
```
● nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
     Active: active (running) since Tue 2025-11-26 15:30:00 UTC
```



Test the web page locally:

```bash
curl localhost
```

You should see your custom HTML.

Exit the SSH session:

```bash
exit
```

### Browser Access Test

Open your web browser and navigate to:

```
http://YOUR_PUBLIC_IP
```

**You should see:**
```
Welcome to terraform-aws-vm
Deployed with Terraform on AWS
Instance ID: i-0123456789abcdef0
Availability Zone: us-east-1a
```

**Success!** Your infrastructure is fully functional.

### Troubleshooting

**If SSH doesn't work:**
- Wait 2-3 minutes for instance initialization
- Check security group allows port 22
- Verify you're using the correct key file
- Ensure key permissions: `chmod 600 ~/.ssh/terraform-aws-key`

**If web page doesn't load:**
- Wait 2-3 minutes for user data script to complete
- Verify security group allows port 80
- Make sure you're using HTTP (not HTTPS)
- Check instance is running in AWS Console
- SSH in and check: `sudo systemctl status nginx`

---

## Part 8: Understanding Terraform State

Terraform tracks infrastructure in a state file.

### View State Files

```bash
ls -la terraform.tfstate*
```

**You'll see:**
- `terraform.tfstate` - Current infrastructure state
- `terraform.tfstate.backup` - Previous state (after changes)

### Query State

List all managed resources:

```bash
terraform state list
```

**Output:**
```
aws_instance.web_server
aws_internet_gateway.main
aws_key_pair.deployer
aws_route_table.public
aws_route_table_association.public
aws_security_group.web_server
aws_subnet.private
aws_subnet.public
aws_vpc.main
```

Show specific resource details:

```bash
terraform state show aws_instance.web_server
```

View all outputs:

```bash
terraform output
```

Get specific output:

```bash
terraform output instance_public_ip
```

### State File Security

**Important:**
- State files contain sensitive data (IPs, IDs, sometimes passwords)
- Never commit to public repositories
- Use remote state (S3) for team collaboration
- Enable state locking to prevent conflicts

---

## Part 9: Cleanup - Destroying Resources

When you're done testing, clean up to avoid charges.

### Destroy Infrastructure

```bash
terraform destroy
```

Terraform shows what will be destroyed:

```
Terraform will perform the following actions:

  # aws_instance.web_server will be destroyed
  - resource "aws_instance" "web_server" {
      - ami                          = "ami-0c55b159cbfafe1f0" -> null
      ...
    }

Plan: 0 to add, 0 to change, 9 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

Type **`yes`** to confirm.

**Destruction Progress:**
```
aws_instance.web_server: Destroying... [id=i-0123456789abcdef0]
aws_instance.web_server: Still destroying... [10s elapsed]
aws_instance.web_server: Destruction complete after 32s
aws_route_table_association.public: Destroying...
aws_route_table_association.public: Destruction complete after 1s
aws_route_table.public: Destroying...
...
aws_vpc.main: Destroying...
aws_vpc.main: Destruction complete after 1s

Destroy complete! Resources: 9 destroyed.
```

### Verify in AWS Console

Check AWS Console to confirm:
- EC2 instances: Terminated
- VPC: Deleted
- Subnets: Deleted
- Security groups: Deleted
- Internet Gateway: Deleted

**Note:** State files remain locally but show zero resources.

---

### Learning Resources

**Official Documentation:**
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

**Tutorials:**
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [AWS Workshops](https://workshops.aws/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

**Tools:**
- [tfsec](https://github.com/aquasecurity/tfsec) - Security scanner
- [terraform-docs](https://terraform-docs.io/) - Documentation generator
- [Infracost](https://www.infracost.io/) - Cost estimation
- [Terragrunt](https://terragrunt.gruntwork.io/) - DRY configurations

**Community:**
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [r/Terraform](https://www.reddit.com/r/Terraform/)
- [AWS Subreddit](https://www.reddit.com/r/aws/)

---

## Conclusion

Congratulations! You've successfully:

✅ Created a complete AWS VPC from scratch  
✅ Deployed public and private subnets  
✅ Configured Internet Gateway and routing  
✅ Set up security groups  
✅ Launched an EC2 instance with automated software installation  
✅ Accessed your infrastructure via SSH and browser  
✅ Managed infrastructure state with Terraform  
✅ Cleaned up resources properly  

### Key Takeaways

1. **Infrastructure as Code** enables reproducible, version-controlled infrastructure
2. **Terraform** manages dependencies and state automatically
3. **Planning** before applying prevents costly mistakes
4. **Proper networking** is fundamental to cloud architecture
5. **Security** should be built in from the start

### What You've Learned

**Technical Skills:**
- Writing Terraform HCL configuration
- AWS VPC networking fundamentals
- EC2 instance management
- Security group configuration
- SSH key pair management
- Infrastructure state management

**DevOps Practices:**
- Infrastructure as Code principles
- Version control for infrastructure
- Security best practices
- Documentation standards
- Troubleshooting methodologies

### Final Thoughts

This is just the beginning of your DevOps journey. The principles you've learned here—automation, version control, security, and documentation—apply to all infrastructure work.

Keep building, keep learning, and remember: every expert was once a beginner who didn't give up.

---

## License

This project is licensed under the MIT License - feel free to use, modify, and distribute.

---

## Acknowledgments

- HashiCorp for Terraform
- AWS for comprehensive documentation
- DevOps community for best practices and support

---

### Tags

`#DevOps` `#Terraform` `#AWS` `#InfrastructureAsCode` `#CloudComputing` `#EC2` `#VPC` `#IaC` `#CloudAutomation` `#AWSNetworking`

---

**Happy Terraforming! 🚀**
