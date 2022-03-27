This is a 3 stage demo that adds functionality for each stage.

Stage01 will clone VMs to an existing portgroup, and adds no functionality like loadbalancer or security.

Stage02 will instead create a T1 router, use a logical segment, and deploy a loadbalancer for only HTTP.

Stage03 will implement a loadbalancer with a certificate, and implement microsegmentation for the application.
Please note you are required to upload your own signed certificate, along with CA certicate to NSX-T before running script.
