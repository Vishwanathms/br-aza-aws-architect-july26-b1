
Want to create VPC, 
Subnets -- 2 Public , 2 Private
Attach the internet gateway to the default Route Table
Attach Public subnets sub1 and sub2 to the default route table
Create NAT gateway using Sub1 for "Zone" option
Create a new route table,
Associate sub3 and sub4 to new route table
Update the new route table with 0.0.0.0/0 towards nat gateway

Variablize it with best practice 
Create terraform.tfvars for input values 



Add Security Group 
Allowing , SSH, ICMP and HTTP

Create keys

Create 1 Public  ec2 instnace in Sub1 public subnet
Create 2 private ec2 instance , one each in each private subnet
Create role for Systems manager
Install SSM on all the ec2 instance and assign the systems manager role on all the ec2 instance.
Using userdata install httpd service and make sure to have different output on index.html
Create target group, for these 2 private ec2 instance on port 80, with health check on index.html
Create loadbalancer ALB, and attach the target group 



