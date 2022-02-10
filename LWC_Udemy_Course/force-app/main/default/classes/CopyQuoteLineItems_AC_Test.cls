/*****************************************************************************
Author      : MST Solutions
CreateDate  : 09/17/2019
Description : This class is used to do unit testing for CopyQuoteLineItems_AC class.
******************************************************************************/
@isTest
public class CopyQuoteLineItems_AC_Test {
    
    static testmethod void qliRecords() {
        Account newAccount = new Account(Name = 'Test');
        insert newAccount;
        
        List<opportunity> oppList = TestClassUtil.createBulkOpportunityRecord(3, newAccount.Id);
        insert oppList;
        
        //Create Product
        List<Product2> newProdList = TestClassUtil.createProduct(1);
        insert newProdList;
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        update standardPricebook;
        
        //Query for the Pricebook2 record, to check IsStandard field
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        //It should return true
        System.assertEquals(true, standardPricebook.IsStandard, 'Price book is not a standard price book');
        
        
        //Create the PricebookEntry
        PricebookEntry priceBook = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = newProdList[0].Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert priceBook;
        
        List<Quote> quoteList = TestClassUtil.createQuote( standardPricebook.Id, oppList[0].Id, 1);
        insert quoteList;
        
        List<QuoteLineItem> quoteLineItemList = TestClassUtil.createQLI(priceBook.Id, quoteList[0].Id, 1);
        insert quoteLineItemList;
        
        CopyQuoteLineItems_AC.getQuoteLineItems(quoteList[0].Id);
        
    }
    
    static testmethod void copyQLI() {
        Account newAccount = new Account(Name = 'Test');
        insert newAccount;
        
        List<opportunity> oppList = TestClassUtil.createBulkOpportunityRecord(3, newAccount.Id);
        insert oppList;
        
        //Create Product
        List<Product2> newProdList = TestClassUtil.createProduct(1);
        insert newProdList;
        
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        update standardPricebook;
        
        //Query for the Pricebook2 record, to check IsStandard field
        standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        //It should return true
        System.assertEquals(true, standardPricebook.IsStandard, 'Not a standard price book');
        
        
        //Create the PricebookEntry
        PricebookEntry priceBook = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = newProdList[0].Id,
            UnitPrice = 1020,
            IsActive = true
        );
        insert priceBook;
        
        List<Quote> quoteList = TestClassUtil.createQuote( standardPricebook.Id, oppList[0].Id, 1);
        insert quoteList;
        
        List<QuoteLineItem> quoteLineItemList = TestClassUtil.createQLI(priceBook.Id, quoteList[0].Id, 1);
        insert quoteLineItemList;
        
        List<Id> qliList = new List<Id>();
        qliList.add(quoteLineItemList[0].Id);
        CopyQuoteLineItems_AC.cloneLineItems(qliList);
        
    }
    
}