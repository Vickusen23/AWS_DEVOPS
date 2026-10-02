AWS 3-TIER ARCHITECTURE — CLI PRACTICE GUIDE (vick_devops)
============================================================
A complete, step-by-step guide using the AWS CLI to provision a
highly available and scalable 3-tier AWS architecture.

Prerequisites:
  - AWS CLI installed
  - Valid credentials configured (aws configure) with permission
    to create networking, compute, and database resources

============================================================
STEP 0: ENVIRONMENT VARIABLES
============================================================
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"

aws configure set default.region $REGION

============================================================
STEP 1: CREATE THE VPC & SUBNETS
============================================================

# 1.1 Create the VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.VpcId' \
  --output text)

aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=vick_devops_vpc

echo "VPC Created: $VPC_ID"

# 1.2 Create Subnets across two AZs (us-east-1a & us-east-1b)
# Public subnets  -> Load Balancer
PUB_SUB1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
PUB_SUB2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# Private app subnets -> EC2 instances
APP_SUB1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.11.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
APP_SUB2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.12.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# Private DB subnets -> RDS
DB_SUB1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.21.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
DB_SUB2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.22.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# 1.3 Auto-assign public IPs on public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB2 --map-public-ip-on-launch

# 1.4 Tag subnets
aws ec2 create-tags --resources $PUB_SUB1 --tags Key=Name,Value=vick_devops_public_subnet_a
aws ec2 create-tags --resources $PUB_SUB2 --tags Key=Name,Value=vick_devops_public_subnet_b
aws ec2 create-tags --resources $APP_SUB1 --tags Key=Name,Value=vick_devops_app_subnet_a
aws ec2 create-tags --resources $APP_SUB2 --tags Key=Name,Value=vick_devops_app_subnet_b
aws ec2 create-tags --resources $DB_SUB1 --tags Key=Name,Value=vick_devops_db_subnet_a
aws ec2 create-tags --resources $DB_SUB2 --tags Key=Name,Value=vick_devops_db_subnet_b

============================================================
STEP 2: GATEWAYS & ROUTE TABLES
============================================================

# 2.1 Internet Gateway (for public subnets)
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=vick_devops_igw
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# Public route table
PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PUB_RT --tags Key=Name,Value=vick_devops_public_rt
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

aws ec2 associate-route-table --subnet-id $PUB_SUB1 --route-table-id $PUB_RT
aws ec2 associate-route-table --subnet-id $PUB_SUB2 --route-table-id $PUB_RT

# 2.2 NAT Gateways (one per AZ — keeps the app tier highly available)
# NAT Gateway in AZ-A
EIP_ALLOC1=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_GW1=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB1 --allocation-id $EIP_ALLOC1 --query 'NatGateway.NatGatewayId' --output text)
aws ec2 create-tags --resources $NAT_GW1 --tags Key=Name,Value=vick_devops_nat_gw_a

# NAT Gateway in AZ-B
EIP_ALLOC2=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NAT_GW2=$(aws ec2 create-nat-gateway --subnet-id $PUB_SUB2 --allocation-id $EIP_ALLOC2 --query 'NatGateway.NatGatewayId' --output text)
aws ec2 create-tags --resources $NAT_GW2 --tags Key=Name,Value=vick_devops_nat_gw_b

echo "Waiting for NAT Gateways to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW1 $NAT_GW2

# Private route tables — one per AZ so each routes to its own NAT Gateway
PRIV_RT_A=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PRIV_RT_A --tags Key=Name,Value=vick_devops_private_rt_a
aws ec2 create-route --route-table-id $PRIV_RT_A --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW1

PRIV_RT_B=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PRIV_RT_B --tags Key=Name,Value=vick_devops_private_rt_b
aws ec2 create-route --route-table-id $PRIV_RT_B --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW2

# Associate with app subnets (one per AZ)
aws ec2 associate-route-table --subnet-id $APP_SUB1 --route-table-id $PRIV_RT_A
aws ec2 associate-route-table --subnet-id $APP_SUB2 --route-table-id $PRIV_RT_B

# Associate with DB subnets
aws ec2 associate-route-table --subnet-id $DB_SUB1 --route-table-id $PRIV_RT_A
aws ec2 associate-route-table --subnet-id $DB_SUB2 --route-table-id $PRIV_RT_B

============================================================
STEP 3: SECURITY GROUPS (TIER-BY-TIER FIREWALL)
============================================================

# 3.1 Load Balancer SG — the ONLY entry point from the internet
ALB_SG=$(aws ec2 create-security-group \
  --group-name vick_devops_alb_sg \
  --description "Security group for public Load Balancer" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0

# 3.2 App SG — only accepts traffic FROM the ALB
APP_SG=$(aws ec2 create-security-group \
  --group-name vick_devops_app_sg \
  --description "Security group for App instances in private subnet" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $APP_SG --protocol tcp --port 80 --source-group $ALB_SG

# 3.3 DB SG — only accepts MySQL traffic FROM the app tier
DB_SG=$(aws ec2 create-security-group \
  --group-name vick_devops_db_sg \
  --description "Security group for RDS database" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $DB_SG --protocol tcp --port 3306 --source-group $APP_SG

============================================================
STEP 4: DATABASE (AMAZON RDS — MULTI-AZ FOR HIGH AVAILABILITY)
============================================================

# 4.1 RDS Subnet Group spanning both DB subnets
aws rds create-db-subnet-group \
  --db-subnet-group-name vick_devops_db_subnet_group \
  --db-subnet-group-description "Subnets for vick_devops RDS Database" \
  --subnet-ids $DB_SUB1 $DB_SUB2

# 4.2 Multi-AZ MySQL instance
aws rds create-db-instance \
  --db-instance-identifier vick-devops-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --multi-az \
  --master-username adminuser \
  --master-user-password "YourStrongPassword123!" \
  --allocated-storage 20 \
  --db-subnet-group-name vick_devops_db_subnet_group \
  --vpc-security-group-ids $DB_SG \
  --no-publicly-accessible \
  --backup-retention-period 1 \
  --storage-encrypted

# NOTE: Multi-AZ RDS takes 10-20 minutes to provision.
# Continue with the next steps while it creates.

============================================================
STEP 5: APPLICATION TIER (LAUNCH TEMPLATE + AUTO SCALING)
============================================================

# 5.1 User Data script
cat << 'EOF' > user_data.sh
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Welcome to vick_devops Application, deployed fully from the CLI!</h1>" > /usr/share/nginx/html/index.html
EOF

# 5.2 Launch Template & Target Group
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
  --query "reverse(sort_by(Images, &CreationDate))[0].ImageId" --output text)

USER_DATA_B64=$(base64 -w 0 user_data.sh 2>/dev/null || base64 user_data.sh)

aws ec2 create-launch-template \
  --launch-template-name vick_devops_launch_template \
  --version-description "v1" \
  --launch-template-data "{
    \"ImageId\":\"$AMI_ID\",
    \"InstanceType\":\"t3.micro\",
    \"SecurityGroupIds\":[\"$APP_SG\"],
    \"UserData\":\"$USER_DATA_B64\",
    \"TagSpecifications\":[{\"ResourceType\":\"instance\",\"Tags\":[{\"Key\":\"Name\",\"Value\":\"vick_devops_app_instance\"}]}]
  }"

TG_ARN=$(aws elbv2 create-target-group \
  --name vick-devops-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --target-type instance \
  --health-check-path "/" \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# 5.3 Auto Scaling Group (min 2 instances = one per AZ; max 4)
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name vick-devops-asg \
  --launch-template LaunchTemplateName=vick_devops_launch_template \
  --min-size 2 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$APP_SUB1,$APP_SUB2" \
  --target-group-arns $TG_ARN

aws autoscaling create-or-update-tags \
  --tags ResourceId=vick-devops-asg,ResourceType=auto-scaling-group,Key=Name,Value=vick_devops_asg,PropagateAtLaunch=true

# 5.4 OPTIONAL — Scaling policy (scale 2 -> 4 instances at 50% CPU)
# Create a file named scaling-policy.json with this content:
#
#   {
#     "PredefinedMetricSpecification": {
#       "PredefinedMetricType": "ASGAverageCPUUtilization"
#     },
#     "TargetValue": 50.0
#   }
#
# Then run:
#
# aws autoscaling put-scaling-policy \
#   --auto-scaling-group-name vick-devops-asg \
#   --policy-name vick_devops_cpu_scale_out \
#   --policy-type TargetTrackingScaling \
#   --target-tracking-configuration file://scaling-policy.json

============================================================
STEP 6: APPLICATION LOAD BALANCER
============================================================

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name vick-devops-alb \
  --subnets $PUB_SUB1 $PUB_SUB2 \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

============================================================
STEP 7: DOMAIN & DNS (ROUTE 53) — OPTIONAL
============================================================

ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)
ALB_ZONE_ID=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "example.com" --query 'HostedZones[0].Id' --output text | cut -d'/' -f3)

cat << EOF > change-batch.json
{
  "Comment": "vick_devops alias record pointing to ALB",
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "app.example.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "$ALB_ZONE_ID",
        "DNSName": "$ALB_DNS",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://change-batch.json

============================================================
VERIFICATION
============================================================

# Wait for instances to pass health checks, then:
echo "http://$ALB_DNS"

# You should see:
#   <h1>Welcome to vick_devops Application!</h1>

============================================================
HOW HA & SCALABILITY ARE ACHIEVED
============================================================

Component    | Mechanism
-------------|------------------------------------------------------------
App tier     | ASG with min 2 instances across 2 AZs — instance or AZ
             | failure is auto-replaced
ALB          | Distributes traffic across healthy targets in both AZs;
             | health checks remove failing instances
DB tier      | --multi-az gives automatic failover to a standby in the
             | other AZ
NAT          | One NAT Gateway per AZ — no single point of failure for
             | outbound traffic
Scaling      | Target tracking policy scales app 2 -> 4 instances at 50% CPU

============================================================
CLEANUP (delete in reverse order to avoid ongoing charges)
============================================================

1. Delete the Auto Scaling Group:
   aws autoscaling delete-auto-scaling-group \
     --auto-scaling-group-name vick-devops-asg --force-delete

2. Delete the Load Balancer:
   aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

3. Wait, then delete the Target Group:
   aws elbv2 delete-target-group --target-group-arn $TG_ARN

4. Delete the RDS instance (takes time; skip final snapshot if practicing):
   aws rds delete-db-instance \
     --db-instance-identifier vick-devops-db \
     --skip-final-snapshot --delete-automated-backups

5. Delete the Launch Template:
   aws ec2 delete-launch-template --launch-template-name vick_devops_launch_template

6. Delete NAT Gateways and wait:
   aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW1
   aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW2
   aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW1 $NAT_GW2

7. Release Elastic IPs:
   aws ec2 release-address --allocation-id $EIP_ALLOC1
   aws ec2 release-address --allocation-id $EIP_ALLOC2

8. Delete the RDS Subnet Group:
   aws rds delete-db-subnet-group --db-subnet-group-name vick_devops_db_subnet_group

9. Delete Security Groups (delete app & db first, then ALB):
   aws ec2 delete-security-group --group-id $APP_SG
   aws ec2 delete-security-group --group-id $DB_SG
   aws ec2 delete-security-group --group-id $ALB_SG

10. Detach & delete the Internet Gateway:
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

11. Delete the VPC:
    aws ec2 delete-vpc --vpc-id $VPC_ID

============================================================
