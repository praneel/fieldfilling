//
// EmailManager : helper class to send emails
// Version April 7th, 2017 : added method to send multiple attached files
// Version August 23st, 2017 : added output text in the email body to explain links
//
public class EmailManager {

   // Public method
    public static void sendMail(String address, String subject, String body) {
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
        
        // Call a helper method to inspect the returned results
        inspectResults(results);
    }

	public static void sendMailWithAttachedFiles(String address, String subject, String body, Map<String,String> attachedFiles) {
        
		List <Messaging.EmailFileAttachment> attachmentList = new List <Messaging.EmailFileAttachment>();
            
		for (String filename : attachedFiles.keyset()) {
			Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
			blob csvBlob = Blob.valueOf(attachedFiles.get(filename));
			csvAttc.setFileName(filename);
			csvAttc.setBody(csvBlob);
			attachmentList.add(csvAttc);
            }
        
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setFileAttachments(attachmentList);
        
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
        
        // Call a helper method to inspect the returned results
        inspectResults(results);  
    }

    
    
    public static void sendMailWithAttachedFile(String address, String subject, String body, String filename, String attached) {
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		blob csvBlob = Blob.valueOf(attached);
		csvAttc.setFileName(filename);
		csvAttc.setBody(csvBlob);
        
        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {address};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        
        // Pass this email message to the built-in sendEmail method 
        // of the Messaging class
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
        
        // Call a helper method to inspect the returned results
        inspectResults(results);  
    }

    public static void sendMailWithLinkedFile(String address, String subject, String body, String filename, String attached) {
        
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
        
        // Call a helper method to inspect the returned results
        inspectResults(results);  
    }

    // Helper method
    private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
        Boolean sendResult = true;
        
        // sendEmail returns an array of result objects.
        // Iterate through the list to inspect results. 
        // In this class, the methods send only one email, 
        // so we should have only one result.
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                //System.debug('Email sent successfully');
            }
            else {
                sendResult = false;
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
        
        return sendResult;
    }
     
}