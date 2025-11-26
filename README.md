# Deploy AWS EC2 Infrastructure with Terraform

A complete Infrastructure as Code (IaC) project that deploys a web server on AWS with custom VPC networking using Terraform.

## Project Overview

This project automates the deployment of a fully functional web server infrastructure on AWS, including:

- Custom VPC with DNS support
- Public and private subnets across different availability zones
- Internet Gateway for external connectivity
- Route tables with proper associations
- Security groups with SSH and HTTP access
- Ubuntu EC2 instance with Nginx web server

## Architecture

```
Internet
    ↓
Internet Gateway
    ↓
Route Table
    ↓
Public Subnet (10.0.1.0/24)
    ↓
Security Group (ports 22, 80, 443)
    ↓
EC2 Instance (Ubuntu + Nginx)
```

**Network Details:**
- VPC CIDR: 10.0.0.0/16
- Public Subnet: 10.0.1.0/24 (us-east-1a)
- Private Subnet: 10.0.2.0/24 (us-east-1b)

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with IAM user credentials
2. **Terraform** installed (version 1.0 or higher)
3. **AWS CLI** installed and configured (version 2.0 or higher)
4. **SSH client** for accessing the EC2 instance
5. Basic knowledge of AWS and networking concepts

## Installation

### Install Terraform

**macOS:**
```bash
brew install terraform
```

**Ubuntu/Debian:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Windows:**
Download from [terraform.io](https://www.terraform.io/downloads)

### Install AWS CLI

Follow the [official AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/GitHer-Muna/Deploy-a-Virtual-Machine-on-AWS-with-Public-Network-Using-Terraform.git
cd Deploy-a-Virtual-Machine-on-AWS-with-Public-Network-Using-Terraform
```

### 2. Configure AWS Credentials

```bash
aws configure
```

Enter your credentials when prompted:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: us-east-1
- Default output format: json

**Getting AWS Credentials:**
1. Log into AWS Console
2. Navigate to IAM → Users → Your user
3. Security credentials → Create access key
4. Choose "Command Line Interface (CLI)"
5. Download and save the credentials securely

### 3. Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-aws-key -N ""
```

This creates two files:
- `~/.ssh/terraform-aws-key` (private key)
- `~/.ssh/terraform-aws-key.pub` (public key)

Set proper permissions:
```bash
chmod 600 ~/.ssh/terraform-aws-key
```

### 4. Review Configuration

The project includes four main files:

- **main.tf** - AWS resource definitions
- **variables.tf** - Input variable declarations
- **outputs.tf** - Output values after deployment
- **terraform.tfvars** - Variable values (customize as needed)

You can modify `terraform.tfvars` to change:
- AWS region
- Project name
- Instance type
- CIDR blocks

### 5. Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider plugin and initializes the working directory.

### 6. Validate Configuration

```bash
terraform validate
```

Ensures your configuration is syntactically correct.

### 7. Preview Changes

```bash
terraform plan
```

Review what Terraform will create. You should see 9 resources to be added.

### 8. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

Deployment takes approximately 2-3 minutes.

## Accessing Your Infrastructure

After successful deployment, Terraform will display output values including:

- **instance_public_ip** - Public IP address of your EC2 instance
- **web_url** - HTTP URL to access the web server
- **ssh_connection_command** - Ready-to-use SSH command

### SSH Access

```bash
ssh -i ~/.ssh/terraform-aws-key ubuntu@<instance_public_ip>
```

Replace `<instance_public_ip>` with the actual IP from the output.

### Web Access

Open your browser and navigate to:
```
http://<instance_public_ip>
```

You should see a custom welcome page showing:
- Project name
- Instance ID
- Availability zone

## Verification

### Check AWS Console

1. Log into AWS Console
2. Navigate to **EC2** → **Instances**
3. Verify instance is running
4. Check **VPC** section for created networking resources

### Verify Nginx

SSH into the instance and check Nginx status:
```bash
sudo systemctl status nginx
```

## Managing the Infrastructure

### View Outputs

```bash
terraform output
```

View specific output:
```bash
terraform output instance_public_ip
```

### View State

```bash
terraform show
```

List managed resources:
```bash
terraform state list
```

### Modify Infrastructure

1. Update the configuration files
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

## Cleanup

When you're done testing, remove all resources to avoid charges:

```bash
terraform destroy
```

Type `yes` to confirm destruction.

Verify in AWS Console that all resources are removed.

## Project Structure

```
.
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable declarations
├── outputs.tf           # Output definitions
├── terraform.tfvars     # Variable values
├── README.md           # This file
├── BLOG.md             # Detailed technical blog
└── .gitignore          # Git ignore rules
```

## Resource Details

### Created Resources

1. **VPC** - Virtual Private Cloud (10.0.0.0/16)
2. **Public Subnet** - Internet-accessible subnet (10.0.1.0/24)
3. **Private Subnet** - Internal subnet (10.0.2.0/24)
4. **Internet Gateway** - Enables internet connectivity
5. **Route Table** - Directs traffic to Internet Gateway
6. **Route Table Association** - Links route table to public subnet
7. **Security Group** - Firewall rules (SSH, HTTP, HTTPS)
8. **Key Pair** - SSH authentication
9. **EC2 Instance** - Ubuntu server with Nginx

### Security Group Rules

**Inbound:**
- Port 22 (SSH) - For remote access
- Port 80 (HTTP) - For web traffic
- Port 443 (HTTPS) - For secure web traffic

**Outbound:**
- All ports - Allows instance to reach internet

## Customization

### Change AWS Region

Edit `terraform.tfvars`:
```hcl
aws_region = "us-west-2"
```

### Change Instance Type

Edit `terraform.tfvars`:
```hcl
instance_type = "t3.small"
```

### Modify Network CIDR

Edit `terraform.tfvars`:
```hcl
vpc_cidr = "172.16.0.0/16"
public_subnet_cidr = "172.16.1.0/24"
private_subnet_cidr = "172.16.2.0/24"
```

## Troubleshooting

### SSH Connection Refused

**Problem:** Cannot connect via SSH

**Solutions:**
- Wait 2-3 minutes for instance initialization
- Verify security group allows port 22
- Check key file permissions: `chmod 600 ~/.ssh/terraform-aws-key`
- Ensure using correct username: `ubuntu` for Ubuntu AMI

### Web Page Not Loading

**Problem:** Browser cannot access the instance

**Solutions:**
- Wait 2-3 minutes for user data script to complete
- Verify security group allows port 80
- Ensure using HTTP (not HTTPS)
- SSH in and check Nginx: `sudo systemctl status nginx`

### AWS Authentication Error

**Problem:** Terraform cannot authenticate with AWS

**Solutions:**
- Verify credentials: `aws sts get-caller-identity`
- Reconfigure AWS CLI: `aws configure`
- Check IAM user has required permissions

### State Lock Error

**Problem:** Terraform state is locked

**Solutions:**
- Wait for other operations to complete
- Check for crashed terraform processes
- Force unlock (cautiously): `terraform force-unlock <lock_id>`

## Security Best Practices

1. **Never commit sensitive files:**
   - terraform.tfstate
   - terraform.tfvars (if contains secrets)
   - SSH keys (.pem, .key files)

2. **Restrict SSH access in production:**
   ```hcl
   cidr_blocks = ["YOUR_IP/32"]  # Instead of 0.0.0.0/0
   ```

3. **Use environment variables for secrets:**
   ```bash
   export TF_VAR_aws_access_key="your-key"
   ```

4. **Enable MFA on AWS account**

5. **Use IAM roles instead of access keys when possible**

## Cost Estimation

**Free Tier Eligible Resources:**
- t2.micro instance (750 hours/month free)
- 30 GB EBS storage
- 15 GB data transfer

**Estimated Monthly Cost (after free tier):**
- EC2 t2.micro: ~$8.50/month
- EBS storage: ~$0.80/month
- Data transfer: Variable

**Total:** ~$9-12/month

Use `terraform destroy` when not actively using to minimize costs.

## Next Steps

1. **Add NAT Gateway** for private subnet internet access
2. **Deploy RDS database** in private subnet
3. **Add Application Load Balancer** for high availability
4. **Implement Auto Scaling** for dynamic capacity
5. **Set up CloudWatch monitoring** and alarms
6. **Add SSL/TLS certificate** for HTTPS
7. **Configure Route 53** for custom domain

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## Technical Blog

For a detailed walkthrough with explanations, see [BLOG.md](BLOG.md)

## License

MIT License - Feel free to use and modify for your projects.

## Author

**Muna**  
DevOps Engineer  
GitHub: [@GitHer-Muna](https://github.com/GitHer-Muna)

## Acknowledgments

- HashiCorp for Terraform
- AWS for cloud infrastructure
- DevOps community for best practices

---

**Questions or Issues?**  
Open an issue on GitHub or reach out via LinkedIn.

**Last Updated:** November 26, 2025
