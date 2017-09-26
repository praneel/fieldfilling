//
//	Class fieldAnalysisBatch : produce a field trip book for a given object
//	Author : Vincent Brenet, vbrenet@salesforce.com
//
//	Instruction for user in the Anonymous Execution Console :
//	fieldAnalysisBatch instance = new fieldAnalysisBatch(<object name>, <query limit>);
//	Id theId = Database.ExecuteBatch(instance, 2000);
//	Where : object name = the name of the object to be analyzed, query limit = max number of records to be analyzed (if 0, no limit)
//	Example : fieldAnalysisBatch instance = new fieldAnalysisBatch('account', 0);
//	
//	Version 18st August, 2017
//	change output format to a more convenient CSV file
//
global class fieldAnalysisBatch implements Database.Batchable<SObject>, Database.stateful  {

	global integer counter;    // total number of records
    global String queryString;  // query string including all the attributes of the object
    global Date currentDate;
    global Map<String, Map<String, Integer>> theResult; // map <RecordTypeName <AttributeName, counter>>
   	global List<String> attributeList;  // list of all analyzed attributes
   	global List<String> recordTypeList; // list of all record types
    global String theObjectName;        // name of the analyzed object
    global Map<ID, String> recordTypeEntriesById;   // map <record type ID, record type name>
    global Map<Integer, Integer> countersByAge;     // map <age, counter>
    global integer maxkey;
    global integer infinitekey;
    global boolean hasRecordType;   // true if the analyzed object has a record type

    //
    // constructor called with the SObject name as a parameter, and an optional query limit
    // 
    global fieldAnalysisBatch (String s, Integer theQueryLimit) {
        theObjectName=s;
        counter = 0;
        currentDate = date.today();

        attributeList = new List<String>();
		recordTypeList = new List<String>();
       
		List<String> objList = new List<String>();
        objList.add(s);
		Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(objList);
       // get the object field map
        Map<String, Schema.SObjectField> fieldMap = descResult[0].fields.getMap();
       // loop in field map to initialize the String list of field names
		for (String fieldName : fieldMap.keySet()) {
            if (fieldName != 'isdeleted' && fieldName != 'masterrecordid') // skip these two attributes
                attributeList.add(fieldName);
       		}
        hasRecordType = fieldMap.containsKey('recordtypeid');
            
       List<Schema.RecordTypeInfo> recordTypeDesc = descResult[0].getRecordTypeInfos();
       // loop in list of record type infos to initialize the String list of record type names
        for (Schema.RecordTypeInfo rti : recordTypeDesc)
            recordTypeList.add(rti.getName());
        recordTypeList.add('nullRecordTypeEntry');
 	   
        // initialize the map of recordtype names by ids
       recordTypeEntriesById = new Map<ID, String>();
 	   Map<Id,Schema.RecordTypeInfo> rtMapById = descResult[0].getRecordTypeInfosById();
        for (ID theID : rtMapById.keyset()) {
            recordTypeEntriesById.put(theId, rtMapById.get(theId).getname() );
        }
        
       // compute the query string
       queryString = 'Select ';
       Integer nbattribute = attributeList.size();
       for (Integer i=0; i<nbattribute;i++) {
           queryString += attributeList[i];
           if (i != (nbattribute-1))
           queryString += ',';
       	}
		queryString += ' from ' + s ;
        if (theQueryLimit != 0) 
            queryString += ' limit ' + theQueryLimit;
        
        theResult = initializeRecordTypeMap();
        countersByAge = initializeAgeCounters(10);
    }
    //
    //	helper method to send final email
    //
    private void sendMailWithLinkedFile(String address, String subject, String body, String filename, String attached) {
        
        Document thedoc = new Document();
        thedoc.name = filename;
        thedoc.body = Blob.valueOf(attached);
        thedoc.contentType = 'text/csv';
        thedoc.type = 'csv';
        thedoc.folderid = UserInfo.getUserId();
        insert thedoc;
        
        String fullDocURL = Url.getSalesforceBaseUrl().toExternalForm() + '/' + thedoc.id;

        String servletURL = Url.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + thedoc.id;
        
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body + '\nLink to ' + filename + ': ' + fullDocURL + '\n\nDownload ' + filename + ': ' + servletURL);
        
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });        
    }
    // 
    // return a zeroed Map of counters by record age
    //
    private Map<Integer, Integer> initializeAgeCounters (integer nbYears){
        Map<Integer, Integer> zeroedMap = new Map<Integer, Integer>();
        maxkey = nbYears;
        infinitekey = 1000;
        for (integer i=0; i<nbYears; i++) {
            zeroedMap.put(i,0);
        }
        zeroedMAp.put(infinitekey,0);	// infinite age
        return zeroedMap;
    }
    
    //
    // return a zeroed Map of attributes - called by initializeRecordTypeMap for each recordType
    // 
    private  Map<String,Integer> initializeMap(){
        Map<String,Integer> theMap = new Map<String,Integer>();
        Integer nbattribute = attributeList.size();
       for (Integer i=0; i<nbattribute;i++) {
           theMap.put(attributeList[i],0);
    	}
    return theMap;
    }
    
    // return a zeroed Map of zeroed Maps of attributes for each record type
    // called by the constructor
    // 
    private Map<String, Map<String, Integer>> initializeRecordTypeMap(){
        Map<String, Map<String, Integer>> theMap = new Map<String, Map<String, Integer>>();
        Integer nbrectype = recordTypeList.size();
        for (Integer i=0; i<nbrectype; i++){
            theMap.put(recordTypeList[i], initializeMap());
        }
        return theMap;
    }
    
    //
    // just do +1 on a field counter
    // 
    @TestVisible private void incrementAttribute(Map<String,Integer> theMap, String attribute) {
        Integer nb = theMap.get(attribute);
        nb++;
        theMap.put(attribute, nb);
    }
    
    // increment all no null attributes of an object instance
    // 
    private void computeAllObjectAttributes (Map<String, Integer> theMap, Sobject theObject) {
        for (String s : attributeList) {
            Object o = theObject.get(s);
            if (o != null)
                incrementAttribute(theMap, s);
        }
    }
    
    //
    // find the record type of the current instance and launch the computeAllObjectAttribute for the instance
    // 
    private void computeObjectInstance(Map<String, Map<String, Integer>> theMap, Sobject theObject) {
        
        counter++;
        
        Object o;
        
        if (hasRecordType) {
        	o = theObject.get('recordtypeid');
        	if (o != null) {
            	String rtname = recordTypeEntriesById.get((ID)o);
            	computeAllObjectAttributes(theMap.get(rtname), theObject);
        		} else
					computeAllObjectAttributes(theMap.get('nullRecordTypeEntry'), theObject);
        }
        else computeAllObjectAttributes(theMap.get('nullRecordTypeEntry'), theObject);
        
        o = theObject.get('LastModifiedDate');
        if (o != null){
            computeRecordAge(((Datetime)o).date());
        }
    }

    //
    // compute age of current record
    // 
    @TestVisible private void computeRecordAge(Date recDate){
        integer nbyears = recDate.daysBetween(currentDate)/365;
        integer theKey;
        if (countersByAge.containsKey(nbyears)) theKey = nbyears;
        else theKey = infinitekey;
        countersByAge.put(theKey, countersByAge.get(theKey) + 1);
    }
    
    //
    // generate a String including the counters for all the record types
    // 
    private String outputAgeStats () {
        String theResult = 'Statistics by age :\n';
        // records by age
        for (Integer theKey : countersByAge.keyset()){
            if (theKey == infinitekey)
                theResult += 'Records aged more than ' + maxkey + ' years : ' + countersByAge.get(theKey) + '\n';
            else
            	theResult += 'Records aged less than ' + (theKey +1) + ' years : ' + countersByAge.get(theKey) + '\n';
        }

        return theResult;
    }
    //
    //  generate the CSV header : first column = "attribute", then list of record type names
    //
    private String computeCSVHeader(Boolean masterExcluded) {
        String theResult = 'Attribute;';
        for (String s : recordTypeList) {
            // exclude Master record type if zero records
            if (s == 'Master' && masterExcluded) continue;
			theResult += s + ';';
        }
        theResult += '\n';
        return theResult;
    }
    //  generate a String including a CSV row for each attribute, each value of the row corresponding to a record type
    //
    private String computeCSVResult(Map<String, Map<String, Integer>> theMap) {
        Boolean masterExcluded = false;
        
        if (theMap.containsKey('Master'))
            masterExcluded = (theMap.get('Master').get('id') == 0);
        
        String theResult = computeCSVHeader(masterExcluded);

        for (String s : attributeList) {
            theResult += s + ';';
            for (String r : recordTypeList) {
                Map<String, Integer> attMap = theMap.get(r);
                if (r == 'Master' && masterExcluded) continue;
                theResult += attMap.get(s) + ';';
            }
            theResult += '\n';
        }

        return theResult;
    }
    //
    // start batch
    //
    global Database.QueryLocator start(Database.BatchableContext ctx){
        return Database.getQueryLocator(queryString);
    }
    
    //
    // execute batch
    //
    global void execute(Database.BatchableContext ctx,List<SObject> sobjects){   
        for (SObject o : sobjects){
        	computeObjectInstance(theResult, o);       
        }    
	}
    
    //
    // terminate batch
    //
	global void finish(Database.BatchableContext ctx){
        String subject = 'Total number of ' + theObjectName + ' records : ' + counter;
        String body = outputAgeStats();
        String filebody = computeCSVResult(theResult);

		sendMailWithLinkedFile(UserInfo.getUserEmail(), subject, body, theObjectName+'.csv', filebody);
	}
}