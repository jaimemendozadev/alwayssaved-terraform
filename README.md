# 🧠 [AlwaysSaved Terraform Infra](https://github.com/jaimemendozadev/alwayssaved-terraform)

Welcome to the **AlwaysSaved** Terraform Infra — the user-facing web app that powers your private, searchable knowledge base for long-form media. Built to deliver fast, intelligent, and intuitive experiences, this interface lets users upload, explore, and query their personal content with ease.

This is the repository for the entire AWS Infra managed by Terraform.

---

## Table of Contents (TOC)
- [Running the Infra](#running-the-infra)
- [File Structure](#file-structure)
- [AlwaysSaved System Design / App Flow](#alwayssaved-system-design--app-flow)

---

---
## Running the Infra



To run the Infra on AWS, first initialize Terraform in your terminal:

```
$ terraform init
```


Then enter the following commands in your terminal:

```
$ terraform plan -var-file="terraform.tfvars"

$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

To tear down the Infra, enter the following command in your terminal:

```
$ terraform destroy -auto-approve
```

<br />


[Back to TOC](#table-of-contents-toc)

---
## File Structure

```
/
|
|__/scripts
|   |
|   |__embedding_service_setup.sh
|   |
|   |__extractor_service_setup.sh
|   |
|   |__frontend_app_setup.sh
|   |
|   |__llm_service_setup.sh
|
|
|__alb.tf
|    
|__certificate_manager.tf    
|    
|__ec2.tf    
|    
|__iam.tf    
|    
|__providers.tf    
|    
|__route53.tf    
|    
|__s3.tf   
|    
|__sg.tf    
|    
|__sqs.tf    
|      
|__variables.tf     
|     
|__vpc.tf   



```

For v1, the File Structure of the repo is pretty flat and all the relevant AWS resources are located in their respective `.tf` files.

Notice the `/scripts` folder in the repo. For each service in the `ec2.tf` file, we run a `setup.sh` file that pulls down the Docker Image of each respective service from ECR and installs/adds any necessary dependencies and environment variables that are needed to get the service up and running.

We install Docker in each service's running ec2 instance as well as the CloudWatch agent to add logs to CloudWatch for telemetry at runtime.

<br />


[Back to TOC](#table-of-contents-toc)

---

## AlwaysSaved System Design / App Flow

<img src="https://raw.githubusercontent.com/jaimemendozadev/alwayssaved-fe-app/refs/heads/main/README/alwayssaved-system-design.png" alt="Screenshot of AlwaysSaved System Design and App Flow" />

Above 👆🏽you will see the entire System Design and App Flow for Always Saved. This diagram more or less shows the AlwaysSaved infra that gets spun up with Terraform.

If you need a better view of the entire screenshot, feel free to [download the Excalidraw File](https://github.com/jaimemendozadev/alwayssaved-fe-app/blob/main/README/alwayssaved-system-design.excalidraw) and view the System Design document in <a href="https://excalidraw.com/" target="_blank">Excalidraw</a>.

<br />

[Back to TOC](#table-of-contents-toc)

---

## Created By

**Jaime Mendoza**
[https://github.com/jaimemendozadev](https://github.com/jaimemendozadev)
