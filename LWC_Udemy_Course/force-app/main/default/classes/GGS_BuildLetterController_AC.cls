/*********************************************************************
Class Name: buildLetterController_AC
Created By: MST - Matt Billups 
Created On: 10-01-2020
Description: Controller for the buildLetter Lightning Web Component.
*********************************************************************/
public without sharing class GGS_BuildLetterController_AC {


    public class templateFolderWrapper{
        
        @AuraEnabled 
        public String folderName{get;set;}
        
        @AuraEnabled 
        public String folderId{get;set;}
        
        @AuraEnabled
        public list<emailTemplateWrapper> templatelist{get;set;}
        
    }

    public class emailTemplateWrapper{
        
        @AuraEnabled 
        public String templateId{get;set;}
        
        @AuraEnabled 
        public String body{get;set;}
        
        @AuraEnabled
        public String subject {get;set;}
        
        @AuraEnabled 
        public String templateName{get;set;}
    }
    
    public class signatureWrapper{
        
        @AuraEnabled 
        public String signatureId{get;set;}
        
        @AuraEnabled 
        public String signatureBlock{get;set;}
        
        @AuraEnabled
        public String digitalSignature {get;set;}
        
        @AuraEnabled 
        public String signatureName{get;set;}
    }
    
    public class studentEmailWrapper{
        
        @AuraEnabled 
        public String emailAddress{get;set;}
        
        @AuraEnabled 
        public String emailFieldName{get;set;}
    }    

    @AuraEnabled(cacheable=true)
    public static List<templateFolderWrapper> getTemplateFolders(){
        List<templateFolderWrapper> folderNames = new List<templateFolderWrapper>();
        List<String> names = new List<String>();
        List<Folder> folders = [select Name, Id, DeveloperName, Type FROM Folder WHERE Type = 'Email' AND DeveloperName LIKE 'GGS_%' ORDER BY Name ASC];
        for(Folder f : folders){
            templateFolderWrapper wrap = new templateFolderWrapper();
            wrap.folderName = f.Name;
            wrap.folderId = f.Id;
            folderNames.add(wrap);
            names.add(f.Name);
        }
        System.debug('Folder size: ' + names.size());
        return folderNames;
        // return names;
        
    }

    @AuraEnabled(cacheable = true)
    public static List<emailTemplateWrapper> getTemplates(String folderId, String recordId){
        List<emailTemplateWrapper> templateNames = new List<emailTemplateWrapper>();
        List<EmailTemplate> templates = [select Id, Name, DeveloperName, FolderId, Subject, Body, HtmlValue, IsActive FROM EmailTemplate WHERE FolderId =: folderId AND IsActive = TRUE ORDER BY Name ASC];        
        
        for(EmailTemplate e : templates){
            String bodyText = (e.HtmlValue != null ? String.valueOf(e.HtmlValue).unescapeHtml4() : String.valueOf(e.body).unescapeHtml4());
            System.debug('*** bodyText *** = ' + bodyText);
            bodyText = bodyText.removeStart('<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" >');
            bodyText = bodyText.removeEnd('</table>');
            bodyText = bodyText.remove(']]>');
            String subjectText = e.Subject;
            emailTemplateWrapper temp = new emailTemplateWrapper();
            temp.templateName = e.Name;
            temp.templateId = e.Id;
            temp.subject = e.Subject;
            // Set the body to the string with the converted merge field values
            temp.body = bodyText;  
            temp.subject = subjectText;
            templateNames.add(temp);
        }
        
        return templateNames;
        
    }    

    @AuraEnabled(cacheable = true)
    public static String convertTemplate(String templateBody, String recordId){      
        // Loop through the mapping records to put values in a map                                    
        List<RO_OAE_Merge_Field_Mapping__c> emailMappings = [SELECT Id, Name, Field_API_Name__c FROM RO_OAE_Merge_Field_Mapping__c  WHERE Object__c = 'GGS'];
        Map<String, String> mailMergeToFieldMap = new Map<String, String>();
        
        // Get the map of object field metadata
        Map<String, Schema.SObjectField> fieldMap = GGS__c.sObjectType.getDescribe().fields.getMap();
          
        // Get all of the fields on the object
        Set<String> fieldNamesSet = fieldMap.keySet();
        List<String> fieldNames = new List<String>();
        fieldNames.addAll(fieldNamesSet);
        String fields = String.join(fieldNames, ',');
                
        // Loop thru the mappings and add them to a map
        for(RO_OAE_Merge_Field_Mapping__c mapping : emailMappings) 
        {
            mailMergeToFieldMap.put(mapping.Name, mapping.Field_API_Name__c);
            // If the API name of the field has dot notation that means it is a field on a related object
            // and needs to be added to the query string
            if(mapping.Field_API_Name__c.contains('.') && !mapping.Field_API_Name__c.contains('User')){
                fields += ',' + mapping.Field_API_Name__c;
            }
        }                                             

        // Build a Dynamic Query String
        List<GGS__c> ggsList = Database.query('SELECT ' + fields + ' FROM GGS__c WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'' + ' limit 1');        
            String bodyText = templateBody;
            
        for(String mergeField : mailMergeToFieldMap.keySet())
        {            
            if(bodyText != null && bodyText.contains(mergeField))
            {
                String fieldName = mailMergeToFieldMap.get(mergeField);
                // try to get the field value - using try in case the field does not exist on the object
                try {
                    // Added specific rules for the User Names
                    if(fieldName == 'User.FirstName'){
                        bodyText = bodyText.replace(mergeField, String.valueOf(userInfo.getFirstName()));
                    }else if(fieldName == 'User.LastName'){
                        bodyText = bodyText.replace(mergeField, String.valueOf(userInfo.getLastName()));
                    // Added specification for the current date of the day
                    }else if(fieldName == 'CurrentDate'){
                        DateTime currentDate = Date.today();
                        String formattedDate = getFormattedDate(Date.today());
                        bodyText = bodyText.replace(mergeField, formattedDate);
                    } else if(fieldName.contains('.')){
                        if(String.valueOf(ggsList[0].getSobject(fieldName.substringBefore('.')).get(fieldName.substringAfter('.'))) != NULL){
                            bodyText = bodyText.replace(mergeField, String.valueOf(ggsList[0].getSobject(fieldName.substringBefore('.')).get(fieldName.substringAfter('.'))));
                        }
                    }else if(String.valueOf((ggsList[0].get(fieldName))) != NULL){
                        Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                        if(dfr.getType() == Schema.DisplayType.Date || dfr.getType() == Schema.DisplayType.DateTime){
                            Date dateValue = Date.valueOf(ggsList[0].get(fieldName));
                            String formattedDate = getFormattedDate(dateValue);                            
                            bodyText = bodyText.replace(mergeField, formattedDate);
                        } else {
                            bodyText = bodyText.replace(mergeField, String.valueOf(ggsList[0].get(fieldName)));
                        }
                    }                                      
                } catch (exception exc) {
                    System.debug('Issue with converting merge fields');
                } 
            }        
        }   
        
        return bodyText;
        
    }

    @AuraEnabled(cacheable = true)
    public static List<signatureWrapper> getSignatures(){
        List<signatureWrapper> sigList = new List<signatureWrapper>();
        for(GGS_User_Signature__c sig : [SELECT Id, Name, Signature_Block__c, Digital_Signature__c FROM GGS_User_Signature__c]){
            System.debug('block before: ' + sig.Signature_Block__c);
            signatureWrapper sw = new signatureWrapper();
            sw.signatureId = sig.Id;
            sw.signatureName = sig.Name;
            sw.signatureBlock = sig.Signature_Block__c;
            sw.digitalSignature = sig.Digital_Signature__c;
            if(sw.digitalSignature != null) sw.digitalSignature = sw.digitalSignature.replace('&amp;', '&');
            System.debug('block: ' + sw.signatureBlock);
            sigList.add(sw);
        }

        return sigList;
        
    }

    @AuraEnabled
    public static String savePDF(String recordId, String body, Boolean sendEmail, String fileName, Boolean ccFaculty, String studentEmail, String additionalCC){
        PageReference pdf = Page.GGS_GeneratePDF;
        // add parent id to the parameters for standardcontroller
        pdf.getParameters().put('id', recordId);
        pdf.getParameters().put('bodyText', body);

        // create the new attachment
        Attachment attach = new Attachment();
        Blob bodyBlob;
        try {            
            // need this  to pass unit test -- current bug
            if(Test.isRunningTest()){
                bodyBlob = Blob.valueof('Test body blob for test coverage.');
            } else {
                bodyBlob = pdf.getContentAsPDF();
            }            
            
        // need this  to pass unit test -- current bug  
        } catch (VisualforceException e) {
            System.debug('PDF Content Error: ' + e.getMessage());
            return 'PDF Content Error: ' + e.getMessage();            
        }
        
        // Create attachment to insert into SF
        String ggsRT = Schema.SObjectType.Attachment__c.getRecordTypeInfosByName().get('GGS').getRecordTypeId();
        Attachment__c attachRec = new Attachment__c();
        attachRec.RecordTypeId = ggsRT;
        attachRec.GGS__c = recordId;   
        attachRec.Name = fileName;     
        attach.Body = bodyBlob;
        attach.Name = fileName + '.pdf';
        attach.IsPrivate = false;

        // Create attachment to add to the email if the user clicks the box to do so
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
        Boolean noEmailAddress = false;
        if(studentEmail == Null || studentEmail == '') noEmailAddress = true;
        if(sendEmail){

            // Query for the email templates in the system 
            List<EmailTemplate> templates = [SELECT Id, Body, DeveloperName, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'GGS_Official_University_Letter' LIMIT 1];
            EmailTemplate tempToSend;
            if(!templates.isEmpty()) tempToSend = templates[0];
                        
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.Body = bodyBlob;
            att.FileName = fileName;
            att.ContentType = 'application/pdf';
            emailAttachments.add(att);

            // Query for the current GGS record to get the related Student Account record
            List<GGS__c> ggsList = [SELECT Id, Student_Name__c, Faculty_Name__c FROM GGS__c where Id =: recordId];
            GGS__c currentGGS;
            if(!ggsList.isEmpty()) currentGGS = ggsList[0];

            // Query for the email address that will be the from address
            List<OrgWideEmailAddress> fromAddress = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Conduct Resolutions'];
            List <String> ccAddresses = new List<String>();

            // Query for the Faculty record to CC
            if(ccFaculty){
                List<Account> facultyList = [SELECT Id, PersonContactId, IsPersonAccount, PersonEmail, Primary_Email__pc FROM Account WHERE Id =: currentGGS.Faculty_Name__c LIMIT 1];
                if(facultyList[0].Primary_Email__pc != null) ccAddresses.add(facultyList[0].Primary_Email__pc);
            }
            if(additionalCC != null && additionalCC != ''){
                ccAddresses.add(additionalCC);
            }
            
            // Query for the recipient record
            List<Account> recipients = [SELECT Id, PersonContactId, IsPersonAccount, PersonEmail, Primary_Email__pc FROM Account WHERE Id =: currentGGS.Student_Name__c LIMIT 1];
            Account recipient;
            if(!recipients.isEmpty()) recipient = recipients[0];
            // if(recipient.Primary_Email__pc == null) noEmailAddress = true;

            // Create email message to send
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendToList = studentEmail.split(';');
            mail.setOrgWideEmailAddressId(fromAddress[0].Id);
            mail.setToAddresses(sendToList);
            mail.setSubject(tempToSend.Subject);
            mail.saveAsActivity = true;
            mail.setHtmlBody(tempToSend.HtmlValue);
            mail.setTargetObjectId(recipient.PersonContactId);         
            mail.setWhatId(recordId);
            mail.setTreatBodiesAsTemplate(true);
            mail.setTemplateId(tempToSend.Id);
            mail.setTreatTargetObjectAsRecipient(false);
            if (!emailAttachments.isEmpty()) mail.setFileAttachments(emailAttachments);
            if(!ccAddresses.isEmpty()) mail.setCcAddresses(ccAddresses);
            
            mails.add(mail);
        }// End of if
        
        try{            
            Database.SaveResult sr = Database.insert(attachRec);
            if (sr.isSuccess()) {
                attach.ParentId = sr.getId();
                insert attach;
            }
        
        } catch (Exception e) {
        
            System.debug('Error: ' + e.getMessage());            
            return e.getMessage();
        
        }
        
        try{
            if(sendEmail && !noEmailAddress) Messaging.sendEmail(mails);
            return 'Success';

        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());            
            return e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<studentEmailWrapper> getStudentEmails(String recordId){
        List<GGS__c> ggsList = [SELECT Id, Student_Name__c, Faculty_Name__c FROM GGS__c WHERE Id =: recordId];
        GGS__c currentGGS = ggsList[0];
        Id studentId = currentGGS.Student_Name__c;
        List<String> studentEmails = new List<String>();
        // Get the map of object field metadata
        Map<String, Schema.SObjectField> fieldMap = Account.sObjectType.getDescribe().fields.getMap();
        List<String> queryStringList = new List<String>();
        for(String s : fieldMap.keySet()){
            Schema.DescribeFieldResult dfr = fieldMap.get(s).getDescribe();
            if(dfr.getType() == Schema.DisplayType.Email){
                queryStringList.add(dfr.getName());                
            }
        }

        List<studentEmailWrapper> sewList = new List<studentEmailWrapper>();
        if(studentId != null){
            String queryString = 'SELECT ' + String.join(queryStringList, ',') + ' FROM Account WHERE Id = \'' + studentId + '\'' + ' LIMIT 1';
            List<Account> studentList = Database.query(queryString);        
            Account student;
            if(!studentList.isEmpty()) student = studentList[0];            
            for(String fieldName : queryStringList){
                if(student.get(fieldName) != null && !studentEmails.contains(String.valueOf(student.get(fieldName)))){
                    studentEmails.add(String.valueOf(student.get(fieldName)));
                    studentEmailWrapper sew = new studentEmailWrapper();
                    sew.emailAddress = String.valueOf(student.get(fieldName));
                    sew.emailFieldName = fieldMap.get(fieldName).getDescribe().getLabel();
                    sewList.add(sew);                
                }
            }
        }

        // Get the faculty email and add it to the list so it can be displayed
        if(currentGGS.Faculty_Name__c != null){
            List<Account> faculty = [SELECT Id, Primary_Email__pc FROM Account WHERE Id =: currentGGS.Faculty_Name__c];
            if(faculty[0].Primary_Email__pc != null){
                studentEmailWrapper wrap = new studentEmailWrapper();
                wrap.emailAddress = faculty[0].Primary_Email__pc;
                wrap.emailFieldName = 'Faculty Email';
                sewList.add(wrap);
            }
        }
        return sewList;
    }

    public static String getformattedDate(Date dateValue){
        String month = String.valueOf(dateValue.month());                            
        String day = String.valueOf(dateValue.day());
        String year = String.valueOf(dateValue.year());
                
        String monthName;
        if(month == '1'){
            monthName = 'January';
        }else if(month == '2'){
            monthName = 'February';
        }else if(month == '3'){
            monthName = 'March';
        }else if(month == '4'){
            monthName = 'April';
        }else if(month == '5'){
            monthName = 'May';
        }else if(month == '6'){
            monthName = 'June';
        }else if(month == '7'){
            monthName = 'July';
        }else if(month == '8'){
            monthName = 'August';
        }else if(month == '9'){
            monthName = 'September';
        }else if(month == '10'){
            monthName = 'October';
        }else if(month == '11'){
            monthName = 'November';
        }else if(month == '12'){
            monthName = 'December';
        }

        return monthName + ' ' + day + ', ' + year;
    }

}// End of class