/*****************************************************************************
Author      : MST Solutions
CreateDate  : 09/10/2019
Description : This class is used to clone the quote line item record from the
custom lightning component related list
******************************************************************************/
public inherited sharing class  CopyQuoteLineItems_AC {
    
    @AuraEnabled
    public Boolean hasError; //Used to verify any exception occurred
    
    @AuraEnabled
    public String userMessage; //Used to hold the custom error message
    
    @AuraEnabled
    public CopyQuoteLineItems_AC copyController;
    
    @AuraEnabled
    public List<QuoteLineItem> clonedQuoteLineItemList;
    
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId){
        return [SELECT Product2Id, Product2.Name, DFProduct__c, Prod_Desc__c, Description  FROM QuoteLineItem WHERE QuoteId =: quoteId];
    }
    
    
    @AuraEnabled
    public static CopyQuoteLineItems_AC cloneLineItems(list<Id> lstConIds){
        CopyQuoteLineItems_AC copyController = new CopyQuoteLineItems_AC();
        copyController.clonedQuoteLineItemList = new List<QuoteLineItem>();
        String dynamicQuery = 'SELECT Id,' + getCreatableFieldsSOQL('QuoteLineItem');
        if(!String.isBlank(dynamicQuery)) {
            dynamicQuery += ' FROM QuoteLineItem WHERE Id IN : lstConIds';
            for(QuoteLineItem qliInfo : Database.query(dynamicQuery)) {
                copyController.clonedQuoteLineItemList.add(qliInfo.clone(false, true));
            }
            if(copyController.clonedQuoteLineItemList.size() > 0) {
                try {
                    system.debug('QLIINFO: '+copyController.clonedQuoteLineItemList);
                    insert copyController.clonedQuoteLineItemList;
                } catch(Exception ex) {
                    copyController.hasError = true;
                    copyController.userMessage = ex.getMessage();
                }
            }
        }
        return copyController;
    }
    
    
    public static string getCreatableFieldsSOQL(String objectName){
        String selects = '';
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
            
        }
        return  selects;
    }
}