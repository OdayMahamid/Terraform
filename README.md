# Terraform Task
A Terraform code that produces the following AWS resources:
(In the default VPC)
- 2 Instances (t2.micro) - with NGINX running on each.
- An Application Load Balancer that forwards the users’ traffic to the servers.



## code:

- ## Create an AWS access key:

  - Create an IAM user.
  - Create the access key under that IAM user.



- ### After creating AWS access key and secret, add them to the code in main.tf under provider "aws" .


     and Create Security Group to allow inbound web traffic.


- ### create two instances .
    
- ## create target group & attach instances to target group:
     the target status should be " Unused " (it'll take a while).
 
  
- ## create load balancer(ALB) & listener :
    make sure to add the Target group created before to the Listeners and routing -forward to .
    now the target group status will change to healthy.
 

### Run Terraform using terminal :

   ```
    terraform init
   ```
 preview code results:


   ```
    terraform plan
   ```
  
run the code:
  
   ```
    terraform apply
   ```
 
 - ####  In your AWS load balancer you'll see the new ALB,chick on the DNS address and open in a browser 
 

   
  
  
