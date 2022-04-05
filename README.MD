This is a 3 stage demo that adds functionality for each stage.

Stage01 will clone VMs to an existing portgroup, and adds no functionality like loadbalancer or security.

Stage02 will instead create a T1 router, use a logical segment, and deploy a loadbalancer for only HTTP.

Stage03 will implement a loadbalancer with a certificate, and implement microsegmentation for the application.
Please note you are required to upload your own signed certificate, along with CA certicate to NSX-T before running script.

Please note this is a work in progress, the "application" is only a html file that is injected to show the round-robin from load-balancer actually works. the database currently does nothing but shows microsegmentation. I'm writing a golang frontend application that will use the database so the application will be upgraded in future to be a little more complex.

howto:

for each folder, cd into the folder and run:

**terraform init** - this downloads the providers required.

**terraform plan** - this will validate that everything is in order.

**terraform apply** - this will run the terraform script and deploy the infrastructure

Now validate that everything looks as expected. Before running the next stage:

**terraform destroy** - to remove everything created and clean up for next stage.
