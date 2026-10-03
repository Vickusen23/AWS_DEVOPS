# 1. Delete Auto Scaling Group (terminates the EC2 instances too)
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name vick-devops-asg --force-delete

# 2. Delete the Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

# 3. Wait ~1 min for the ALB to fully disappear, then delete the Target Group
aws elbv2 delete-target-group --target-group-arn $TG_ARN

# 4. Delete the RDS database (takes 5-10 min, runs in background)
aws rds delete-db-instance --db-instance-identifier vick-devops-db --skip-final-snapshot --delete-automated-backups

# 5. Delete the Launch Template
aws ec2 delete-launch-template --launch-template-name vick_devops_launch_template

# 6. Delete the NAT Gateways and wait for them to go away
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW1
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW2
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW1 $NAT_GW2

# 7. Release the Elastic IPs (THIS stops the biggest charges)
aws ec2 release-address --allocation-id $EIP_ALLOC1
aws ec2 release-address --allocation-id $EIP_ALLOC2

# 8. Delete the RDS Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name vick_devops_db_subnet_group

# 9. Delete Security Groups (order matters — ALB SG last)
aws ec2 delete-security-group --group-id $APP_SG
aws ec2 delete-security-group --group-id $DB_SG
aws ec2 delete-security-group --group-id $ALB_SG

# 10. Detach and delete the Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 11. Delete the VPC (only works if ALL resources inside are gone)
aws ec2 delete-vpc --vpc-id $VPC_ID

# If you get an error like DependencyViolation on step 9, 10, or 11: something inside the VPC is still deleting. Wait 2–3 minutes and retry that specific command — don't re-run everything.
# If your terminal session is closed (variables lost), run this first to recover them, then run the cleanup above:
