@isTest
public class testFieldAnalysisBatch {
    
    @isTest static void testfab1() {
       	fieldAnalysisBatch instance = new fieldAnalysisBatch('Lead', 0);
        Map<String,Integer> theMap = new Map<String,Integer>();
        theMap.put('id',5);
        instance.incrementAttribute(theMap,'id');
        Date d = Date.today();
        instance.computeRecordAge(d);
		ID theID = Database.ExecuteBatch(instance, 2000);
        
    }
    
        @isTest static void testfab2() {
       	fieldAnalysisBatch instance = new fieldAnalysisBatch('Lead', 200);
		ID theID = Database.ExecuteBatch(instance, 500);
    }

}