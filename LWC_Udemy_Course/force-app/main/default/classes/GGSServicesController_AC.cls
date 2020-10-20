/*********************************************************************
Class Name: GGSServicesController_AC
Created By: MST - Robert Jaramillo 
Created On: 09-17-2020
Description: Controller for GGSServices_VF & GGSConfirmationPage_VF.
*********************************************************************/
public class GGSServicesController_AC {
    
    private final GGS__c ggsServiceViolation;
    public Blob afile {get; set;}
    public String contentType {get; set;}
    public String fileName {get; set;}
    public String studentName {get; set;}
    public String studentIRN {get; set;}
    public String instructorName {get; set;}
    public String instructorIRN {get; set;}
    public String instructorEmail {get; set;}
    public String recordName {get; set;}
    
    //Constructor - set GGS record fields
    public GGSServicesController_AC(ApexPages.StandardController stdController){
        Id rtId = Schema.SObjectType.GGS__c.getRecordTypeInfosByName().get(RecordTypeConstants_AC.GGS_AVT_RT).getRecordTypeId();
        this.ggsServiceViolation=(GGS__c)stdController.getRecord();
        this.ggsServiceViolation.Status__C = 'Evaluate';
        if(String.isNotBlank(rtId)) {
            this.ggsServiceViolation.RecordTypeId = rtId;
        }
    }
    
    //Set fields on GGSServices_VF Page
    public void setFields() {
        setStudentFields();
        setFacultyFields();
        setCourseFields();
        setOwner();
    }
    
    //Create GGS record with attachments
    public PageReference createCaseWithAttachment() {
        Attachment__c custAtt;
        Attachment standardAtt;
        
        try{
            //Insert GGS AVT record
            insert ggsServiceViolation;

        }catch(DmlException e){
            ApexPages.addMessages(e);
            ApplicationLogs__c appLog = new ApplicationLogs__c(Event_Type__c = 'AVT_SITE' , Class_Name__c = 'GGSServicesController_AC', 
                                                               Error_Message__c = e.getMessage(), StackTrace__c	= e.getStackTraceString(), 
                                                               Line_Number__c = String.valueOf(e.getLineNumber()));
            insert appLog;
            return null;
        }
        
        try{
            if(this.afile != null) {
                //Create custom attachment
                if(String.isNotBlank(ggsServiceViolation.Id)) {
                    custAtt = createCustomAttachment(ggsServiceViolation.Id);
                    insert custAtt;
                }
                
                //Create attachment
                if(String.isNotBlank(custAtt.Id)) {
                    standardAtt = createAttachment(custAtt.Id);
                    insert standardAtt;
                }
            }
        }catch(Exception e) {
            String errorMessage = 'Error uploading document. ' + e.getMessage() + '. Please send file to the following email address: \n' + Label.VAT_Email;
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMessage));
            ApplicationLogs__c appLog = new ApplicationLogs__c(Event_Type__c = 'AVT_SITE' , Class_Name__c = 'GGSServicesController_AC', 
                                                               Error_Message__c = errorMessage, StackTrace__c	= e.getStackTraceString(), 
                                                               Line_Number__c = String.valueOf(e.getLineNumber()));
            insert appLog;
            return null;            
        }
        
        try{
            //Redirect user to confirmation page
            if(String.isNotBlank(ggsServiceViolation.Id)) {
                List<GGS__c> newGGSRecord = [SELECT Name FROM GGS__c WHERE Id =: ggsServiceViolation.Id];
                if(!newGGSRecord.isEmpty()) {
                    PageReference p = new PageReference('/apex/GGSConfirmationPage_VF?recordName=' + newGGSRecord[0].Name);
                    p.setRedirect(true);
                    return p;                }
            }            
        }catch(Exception e) {
            ApexPages.addMessages(e);
            ApplicationLogs__c appLog = new ApplicationLogs__c(Event_Type__c = 'AVT_SITE' , Class_Name__c = 'GGSServicesController_AC', 
                                                               Error_Message__c = e.getMessage(), StackTrace__c	= e.getStackTraceString(), 
                                                               Line_Number__c = String.valueOf(e.getLineNumber()));
            insert appLog;
            return null;
        }      
        return null;
    }
    
    //Set fields on GGSConfirmationPage_VF
    public void setFieldsOnConfirmation() {
        String rName = ApexPages.currentPage().getParameters().get('recordName');
        if(String.isNotBlank(rName)) {
            this.recordName = rName;
        }
    }
    
    //Set student fields on GGSServices_VF Page
    private void setStudentFields() {
        String irn = ApexPages.currentPage().getParameters().get('irn');
        if(String.isNotBlank(irn)) {
            List<Account> studentList = getAccountByIRN(irn);
            if(!studentList.isEmpty()){
                if(String.isNotBlank(studentList[0].Person_IRN__c)) {
                    studentIRN = studentList[0].Person_IRN__c;
                }
                if(String.isNotBlank(studentList[0].Name)) {
                    studentName = studentList[0].Name;
                }
                this.ggsServiceViolation.Student_Name__c = studentList[0].Id;
            }else {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Student not found with provided IRN.'));
            }            
        }else {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Student IRN not provided.'));
        }
    }
    
    //Set faculty fields on GGSServices_VF page
    private void setFacultyFields() {
        String facultyirn = ApexPages.currentPage().getParameters().get('facultyirn');
        if(String.isNotBlank(facultyirn)) {
            List<Account> facultyList = getAccountByIRN(facultyirn);
            if(!facultyList.isEmpty()){
                if(!facultyList[0].Is_Faculty__c){
                    updateAccount(facultyList[0], 'FACULTY');
                }
                if(String.isNotBlank(facultyList[0].Person_IRN__c)) {
                    instructorIRN = facultyList[0].Person_IRN__c;
                }
                if(String.isNotBlank(facultyList[0].Name)) {
                    instructorName = facultyList[0].Name;
                }
                if(String.isNotBlank(facultyList[0].Primary_Email__pc)) {
                    instructorEmail = facultyList[0].Primary_Email__pc;
                }
                this.ggsServiceViolation.Faculty_Name__c = facultyList[0].Id;
            }else {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Faculty not found with provided IRN.'));
            }
        }else {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Faculty IRN not provided.'));
        }
    }
    
    //Assign queue as owner
    private void setOwner() {
        List<QueueSobject> avtQueue = [SELECT QueueId, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName =: Constants_AC.AVT_QUEUE];
        if(!avtQueue.isEmpty()) {
            this.ggsServiceViolation.OwnerId = avtQueue[0].QueueId;
        }
    }
    
    //Make a service callout to obtain course info using courseNum from GGSServices_VF page parameters
    private void setCourseFields() {
        String courseNum = ApexPages.currentPage().getParameters().get('CourseNum');
        if(String.isNotBlank(courseNum)){
            String courseOfferingResponse = PlatformServiceCallouts_AC.getCourseOffering(courseNum);
            if(String.isNotBlank(courseOfferingResponse)){
                CourseOfferingWrapper_AC courseOfferingWrapper = (CourseOfferingWrapper_AC)JSON.deserialize(courseOfferingResponse, CourseOfferingWrapper_AC.class);
                if(String.isNotBlank(courseOfferingWrapper.courseCode)){
                    this.ggsServiceViolation.Course_ID__c = courseOfferingWrapper.courseCode;
                }
                if(String.isNotBlank(courseOfferingWrapper.code)){
                   this.ggsServiceViolation.Group_ID__c = courseOfferingWrapper.code;
                }
                if(courseOfferingWrapper.dateRange != null && String.isNotBlank(courseOfferingWrapper.dateRange.startDate)) {
                    this.ggsServiceViolation.AVT_Course_Start_Date__c = DateUtility_AC.parseDateTime(courseOfferingWrapper.dateRange.startDate).date();
                }                
            }
        }else {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Course offering number not provided.'));
        }
    }
    
    //Get Account By IRN
    public List<Account> getAccountByIRN(String irn) {
        return [SELECT Id, Person_IRN__c, Name, Is_Faculty__c, Caller_Type__c, Primary_Email__pc 
                FROM Account WHERE Person_IRN__c =: irn];
    }
    
    //Update Caller_Type__c
    private void updateAccount(Account accountRec, String callerType) {
        if(accountRec != null) {
            Account accountToUpdate = new Account();
            accountToUpdate.Id = accountRec.Id;
            accountToUpdate.Caller_Type__c = callerType;
            update accountToUpdate;
        }       
    }
    
    private Attachment__c createCustomAttachment(String parentId) {
        Attachment__c cusAtt = new Attachment__c();
        cusAtt.GGS__c = parentId;
        
        //Get RecordType Id
        Id ggsRT = Schema.SObjectType.Attachment__c.getRecordTypeInfosByName().get(RecordTypeConstants_AC.GGS_RT).getRecordTypeId();
        if(String.isNotBlank(ggsRT)) {
            cusAtt.RecordTypeId = ggsRT;
        }
        return cusAtt;
    }
    
    //Create Attachment
    private Attachment createAttachment(String parentId) {
        Attachment attach=new Attachment();
        attach.Body = this.afile;
        attach.Name = this.filename;
        attach.ContentType = this.contentType;
        attach.ParentID = parentId;
        return attach;
    }
}