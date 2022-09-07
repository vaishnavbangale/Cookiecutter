# Cookiecutter Service Initliazation

## Prerequisites
- Access to [Developer Portal](https://hm-backstage.dev.aws-ue1.happymoney.com/) 

## Usage 
1) Navigate to [Developer Portal](https://hm-backstage.dev.aws-ue1.happymoney.com/) 
2) On the home page, go to **Create Component**
3) Choose **Service Initialization Automation**
4) Enter the name of your service (other areas will be autopopulated). **DO NOT INCLUDE UNDERSCORES FOR SERVICE NAME!**
5) Select the name of the team you belong to. If you do not see yours please create a ticket to include it.
6) OPTIONAL - Check **Create Code Pipelines for the repo** if you want pipelines created for your project. At this moment it only creates a dev pipeline which will expand to more environments in the future 
7) Click **Next Step** and you will now be shown review section to confirm. Select **Confirm** and creation process will begin.
Github repository (and pipeline if selected) will now begin creation process. This will take about 10 minutes or so. After it is done, you can view your repo in github and pipeline in AWS CodePipeline. 

## Features

To read about features, see here: [Features](./{{cookiecutter.service_id}}/Features.md). This file will be included in the generated repository for later reference.
