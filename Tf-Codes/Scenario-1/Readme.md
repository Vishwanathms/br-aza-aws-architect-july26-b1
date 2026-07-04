
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

Create 2 ec2 instnace , one in Sub1 public subnet
another in private sub1 
Using the same keys and same security groups
