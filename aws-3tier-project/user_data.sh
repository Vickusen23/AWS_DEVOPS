# 5.1 User Data script
cat << 'EOF' > user_data.sh
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Welcome to vick_devops Application!</h1>" > /usr/share/nginx/html/index.html
EOF
