/* eslint-disable no-eval */
/* eslint-disable no-console */
import {LightningElement, track, api} from 'lwc';

// Importing apex class methods
import getQuoteLineItems from '@salesforce/apex/CopyQuoteLineItems_AC.getQuoteLineItems';
import cloneLineItems from '@salesforce/apex/CopyQuoteLineItems_AC.cloneLineItems';

// Importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// datatable columns
const columns = [
    {
        label: 'PRODUCT',
        fieldName: 'Product2.Name'
    }, {
        label: 'DF PRODUCT',
        fieldName: 'DFProduct__c'
    }, {
        label: 'DESCRIPTION',
        fieldName: 'Prod_Desc__c',
    }, {
        label: 'LINE ITEM DESCRIPTION',
        fieldName: 'Description',
    }
];

export default class CopyQuoteLineItems extends LightningElement {
    
    // Reactive variable
    @track data;
    @track columns = columns;
    @track recordsCount = 0;
    @track openmodel = false;
    @track disableCloneBtn = false;

    // Non-reactive variables
    @api recordId;
    selectedRecords = [];
    error;

    // Retrieving the data using wire service
    retriveQuotLineItem() {
        getQuoteLineItems({quoteId: this.recordId})
            .then(result => {
                if(result.length !== 0) {
                    this.openmodel = true;
                    this.data = result.map(
                        record => Object.assign(
                          { "Product2.Name": record.Product2.Name },
                          record
                        )
                      );
                    //this.data = result;
                } else {
                    this.closeModal();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: 'No Quote Line Item(s) have been added to this quote; please add a product.', 
                            variant: 'info'
                        }),
                    );
                }
                this.error = undefined;
            })
            .catch(error => {
                window.console.log('error====> '+ error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Failure!', 
                        message: error.message,
                        variant: 'error'
                    }),
                );
            });
    }

    // Getting selected rows 
    getSelectedRecords(event) {
        // getting selected rows
        const selectedRows = event.detail.selectedRows;
        this.recordsCount = event.detail.selectedRows.length;
        let conIds = new Set();
        // getting selected record id
        for (let i = 0; i < selectedRows.length; i++) {
            conIds.add(selectedRows[i].Id);
        }
        // coverting to array
        this.selectedRecords = Array.from(conIds);
        window.console.log('selectedRecords ====> ' +this.selectedRecords);
    }

    // Check for selections
    validatedSelectedRecord() {
        if (this.selectedRecords.length) {
            this.disableCloneBtn = true;
            // cloning records
            this.cloneRecords();
        } else {
            this.disableCloneBtn = false;
            // show warning message
            this.dispatchEvent(
                new ShowToastEvent({
                    message: 'Please select Quote Line Item(s) to copy.', 
                    variant: 'warning'
                }),
            );
        }
    }

    // Reset the selection and close the model
    closeModal() {
        this.selectedRecords = [];
        this.openmodel = false;
        this.disableCloneBtn = false;
    } 


    // Clone records
    cloneRecords() {
        cloneLineItems({lstConIds: this.selectedRecords})
        .then(result => {
            window.console.log('result ====> ' + result);
            // showing success message
            if(result.hasError) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while getting Quote Line Items', 
                        message: result.userMessage, 
                        variant: 'error'
                    }),
                );
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'Success! Copied n Quote Line Item record(s).', 
                        variant: 'success'
                    }),
                );
            } 
            this.closeModal();
            this.selectedRecords = [];
            // Clearing selected row indexs 
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.recordsCount = 0;
            // refreshing table data using refresh apex
            eval("$A.get('e.force:refreshView').fire();");

        })
        .catch(error => {
            window.console.log('error====> '+ error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while getting Quote Line Items', 
                    message: error.message, 
                    variant: 'error'
                }),
            );
        });
    }
}