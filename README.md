
<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>




# fieldfilling
This package is a Salesforce utility counting for each field of a given object the number of records which are filled.  
It's implemented as an Apex batch class so it can handle millions of records.  
# Getting started

# Using it from the Exexute Anonymous console 


fieldAnalysisBatch instance = new fieldAnalysisBatch(<object name>, <query limit>);
Id theId = Database.ExecuteBatch(instance, 2000);
Where : object name = the name of the object to be analyzed, query limit = max number of records to be analyzed (if 0, no limit)
Example : fieldAnalysisBatch instance = new fieldAnalysisBatch('account', 0);

  
  
## Prerequisites
The package comes as an Apex class (+ its test class) to deploy into a Salesforce org. 
The package includes also a (bash) shell to launch the utility at CLI level, leveraging SFDX CLI utilities.  
If you want to use the CLI, you need to have SFDX up and running on your desktop.  
If you dont want to use the CLI, the batch can be launched in the anonymous APEX window of the developer console.  
You must be registered as an active user admin in the target org.  
## Installing
Download the package, deploy the two classes into the target org using *sfdx force:mdapi:deploy* or *ant*.  
(The class must be deployed in the org as this is a batch class).  
## Using the shell script
Assuming that you have registered your org in SFDX (sfdx force:auth:web:login ...), then :  
  
sh ff.sh <org> <object> [max record number] [size of batch units]
  
examples :  
  *sh ff.sh myorg Account* # launch the batch for all Account records of myorg, with a default batch unit size of 2000  
  *sh ff.sh Lead 1500* # launch the batch for up to 1500 Lead records  
  *sh ff.sh Cust__c 1200 400* # launch the batch for up to 1200 Cust__c records - the batch unit size will be of 400 so it's likely you'll have 3 batch units  
 
