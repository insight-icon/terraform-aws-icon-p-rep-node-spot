# terraform-aws-icon-p-rep-node

Terraform module to run a public representative node for the ICON Blockchain. Module is intended to be run via 
Terragrunt, a Terraform wrapper.

This is the spot version of [terraform-aws-icon-p-rep-node](https://github.com/robc-io/terraform-aws-icon-p-rep-node) 
only to be used on TestNet. 

### Sources 

- [terraform-shell-resource](https://github.com/matti/terraform-shell-resource)
    - Had issues with provider so copied code over manually 

### Components 

- ec2
    - Bootstraps docker-compose through user-data 
- spot instance request 
    - About to decou

### user-data 

- updates / upgrades 
- python 
    - rm? - Could use for an additional step 
- docker 
- mounts data volume 
- cloudwatch agent 
    - pulls config from bucket 
- prints docker-compose 
- TODO:
    - keystore
    - run docker-compose 

### Secrets 

TODO

Right now we do not have an adequate secrets storing solution.  Until we get Hashicorp vault running, we need a script 
that scp's the keystore over from a provisioning step (TODO: Soe San - Insight), a null_resource (Rob - Insight). 
We are working on getting vault running though so it is a judgement call. 

Planning: 
- Because this module will only be run on TestNet, we can shortcut some provisioning steps that would need vault and 
just provide a path to the testnet keystore 
- Vault option can be built in with logic for testing 


### IAM Roles Needed in Instance Profile 

- EBS mount policy 
- Cloudwatch logs put 
- S3 read 


### What this doesn't include 

- Does not include VPC or any ALB 
- Does not include security groups as we will be building in various features to have automated IP whitelisting 
updates based on the P-Rep IP list - https://download.solidwallet.io/conf/prep_iplist.json
- Does not include any logging or alarms as this will be custom     
