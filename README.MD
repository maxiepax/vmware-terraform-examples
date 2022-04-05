These are some examples that i've written in terraform that showcase usecases of using Terraform against VMwares SDDC.
Most of these are work in progress, they work, but may not have all functionality i would have wanted.

**two-tier-app-with-lb-useg** - demo that shows the 3 stages of automation. <br/>
stage01 starts with just deploying VMs onto a portgroup, no load balancer, no security<br/>
stage02 creates a T1 router, logical segment, and provisions application to the segment, no load balancer, no security.<br/>
stage03 adds load balancer with ssl termination, and microsegmentation.<br/>
