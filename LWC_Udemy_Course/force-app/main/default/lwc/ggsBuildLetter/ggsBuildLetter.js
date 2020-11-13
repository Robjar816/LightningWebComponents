import { LightningElement, api, wire, track } from 'lwc';
import getTemplateFolders from '@salesforce/apex/GGS_BuildLetterController_AC.getTemplateFolders';
import getTemplates from '@salesforce/apex/GGS_BuildLetterController_AC.getTemplates';
import convertTemplate from '@salesforce/apex/GGS_BuildLetterController_AC.convertTemplate';
import getSignatures from '@salesforce/apex/GGS_BuildLetterController_AC.getSignatures';
import savePDF from '@salesforce/apex/GGS_BuildLetterController_AC.savePDF';
import getStudentEmails from '@salesforce/apex/GGS_BuildLetterController_AC.getStudentEmails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

export default class BuildLetter extends LightningElement {
    formats = ['font', 'size', 'bold', 'italic', 'underline',
        'strike', 'list', 'indent', 'align', 'link',
        'image', 'clean', 'table', 'header',
        'background', 'code', 'code-block', 'script', 
        'blockquote', 'direction'];
    @api recordId;
    @track folderId;
    folderOptionList;
    templateOptionList;
    selectedFolder;
    selectedTemplate;
    selectedTemplateName;
    eTemplateList = [];
    body = '';
    signatureOptionList = [];
    selectedSignature
    selectedBlock
    showModal = false;
    sendEmail = false;
    errorStatus = false;
    errorMessage = '';
    displaySpinner = false; 
    emailOptions;
    selectedEmail = '';
    ccEmail = false;
    showEmailModal = false;
    showOtherEmails = true;
    selectedEmailsList = [];
    ccFaculty = false;
    sendCcEmail = false;
    facultyEmail;
    primaryEmail;
    additionalCC;

    @wire(getTemplateFolders)
        wiredFolders({data, error}) {
            if(data){
                this.errorMessage = undefined;
                let folderList = [];
                for(let i = 0; i < data.length; i++){
                    folderList.push({label: data[i].folderName, value: data[i].folderId});                   
                }
                this.folderOptionList = folderList;
            }
            if(error){
                console.log('Error: ' + error.body.message);
                this.errorStatus = true;
                this.errorMessage = error.body.message;
                this.folderOptionList = undefined;
                this.showToast('Error', error.body.message, 'error', 'sticky')
            }
        }

    @wire(getSignatures)
        wiredSignatures({data, error}) {
            if(data){
                this.errorMessage = undefined;
                let sigList = [];
                for(let i = 0; i < data.length; i++){
                    sigList.push({label: data[i].signatureName, value: data[i].digitalSignature, sigBlock: data[i].signatureBlock, digital: data[i].digitalSignature});                   
                }
                this.signatureOptionList = sigList;
            }
            if(error){
                console.log('Error: ' + error.body.message);
                this.errorStatus = true;
                this.errorMessage = error.body.message;
                this.folderOptionList = undefined;
                this.showToast('Error', error.body.message, 'error', 'sticky')
            }
        }

    @wire(getStudentEmails, {recordId: '$recordId'})
        wiredEmails({data, error}) {
            if(data){
                this.errorMessage = undefined;
                let emailList = [];
                var emailStringList = [];
                for(let i = 0; i < data.length; i++){
                    if(data[i].emailFieldName !== 'Faculty Email'){
                        if(data[i].emailFieldName === 'Email'){
                            // emailList.push({label: 'Primary ' + data[i].emailFieldName + ' - ' + data[i].emailAddress, value: data[i].emailAddress});
                            this.primaryEmail = data[i].emailAddress;
                        }else{
                            emailList.push({label: data[i].emailFieldName + ' - ' + data[i].emailAddress, value: data[i].emailAddress});
                        }

                        if(!emailStringList.includes(data[i].emailAddress)){
                            emailStringList.push(data[i].emailAddress);
                        }
                    }else{
                        this.facultyEmail = data[i].emailAddress;
                    }
                }
                this.emailOptions = emailList;                
                var allEmails = emailStringList.join(';');
                this.emailOptions.unshift({label: 'All Student Emails', value: allEmails});
                console.log('emailOptions: ' + this.emailOptions);
            }
            if(error){
                console.log('Error: ' + error.body.message);
                this.errorStatus = true;
                this.errorMessage = error.body.message;
                this.folderOptionList = undefined;
                this.showToast('Error', error.body.message, 'error', 'sticky')
            }
        }        
    
    onSelectFolder(event) {
        console.log('selectedEmail: ' + this.selectedEmail);
        this.selectedFolder = event.target.value;       
        getTemplates({
            folderId: this.selectedFolder,
            recordId: this.recordId,
        })
        .then(result => {
            let tempList = [];
            for(let i = 0; i < result.length; i++){
                tempList.push({label: result[i].templateName, value: result[i].templateId});                   
            }
            this.templateOptionList = tempList;
            this.eTemplateList = result;
        })
        .catch(error => {
            this.errorStatus = true;
            this.errorMessage = error.body.message;
            console.log('ERROR: ' + this.errorMessage);
            this.showToast('Error', this.errorMessage, 'error', 'sticky')
        })         
    }

    onSelectEmailTemplate(event) {
        this.selectedTemplate = event.target.value;
        let templateName = '';
        this.body = '';
        this.selectedSignature = '';        
        var textBody;
        this.eTemplateList.forEach(function (element) {                
            if (element.templateId === event.target.value && element.body != null) {
                textBody = element.body;
                templateName = element.templateName;
                //console.log('Body: ' + textBody);
            }
        });
        this.selectedTemplateName = templateName;

        // Take out the <p> and </p> tags added when the body is retrieved from the template record and replace with </br> tags
        // This is so that the formatting appears correct in the rich text field of the LWC
        //textBody = this.replaceParagraphs(textBody);
        //console.log('Body replaced: ' + textBody);
        convertTemplate({
            templateBody: textBody,
            recordId: this.recordId,
        })
        .then(result => {
            //console.log('result: ' + result);     
            this.body = result;

        })
        .catch(error => {
            this.errorStatus = true;
            this.errorMessage = error.body.message;
            console.log('ERROR: ' + this.errorMessage);
            this.showToast('Error', this.errorMessage, 'error', 'sticky')
        })        
    }

    onSelectSignature(event) {
        this.selectedSignature = event.target.value;
        let selectedSigRecord = this.signatureOptionList.find(element => element.value === this.selectedSignature);
        this.selectedBlock = selectedSigRecord.sigBlock;
        this.selectedSignature.replace('&amp;', '&');
        if(this.body !== null && this.body !== undefined && this.body !== ''){
            let tempBlock = this.replaceParagraphs(this.selectedBlock);
            let tempString = this.body.concat(this.selectedSignature);
            let tempString2 = tempString.concat(this.selectedBlock);
            this.body = tempString2;
        }else {
            let tempString = this.selectedSignature;
            let tempString2 = tempString.concat(this.selectedBlock);
            this.body = tempString2;
        }
    }

    onSelectEmail(event) {
        this.selectedEmail = event.target.value;
    }
    
    bodyUpdate(event) {
        this.body = event.target.value;
        console.log('BODY UPDATED: ' + this.body);
    }

    previewLetter() {      
        convertTemplate({
            templateBody: this.body,
            recordId: this.recordId,
        })
        .then(result => {
            console.log('result: ' + result);     
            this.body = result;
            this.showModal = true;

        })
        .catch(error => {
            this.errorStatus = true;
            this.errorMessage = error.body.message;
            console.log('ERROR: ' + this.errorMessage);
            this.showToast('Error', this.errorMessage, 'error', 'sticky')
        })   
    }

    showToast(titleStr, messageStr, variantStr, modeStr) {
        
        const event = new ShowToastEvent({
            title: titleStr,
            message: messageStr,
            variant: variantStr,
            mode: modeStr
        });
        this.dispatchEvent(event);
    }

    savePDF() {
        this.showSpinner();   
        if((this.sendEmail && this.selectedEmail === '') || (this.sendEmail && this.selectedEmail === null)){
            this.hideSpinner();
            this.showToast('Error', 'There is no email address to send to', 'error', 'pester');
        } else {
            let pdfBody = this.replaceParagraphs(this.body);
            pdfBody = this.replaceDoubleBreak(pdfBody);
            pdfBody = this.replaceIndent(pdfBody);
            savePDF({
                recordId: this.recordId,
                body: pdfBody,
                sendEmail: this.sendEmail,
                fileName: this.selectedTemplateName,
                ccFaculty: this.ccFaculty,            
                studentEmail: this.selectedEmail,
                additionalCC: this.additionalCC
            })
            .then(result => {
                this.hideSpinner();
                if(result === 'Success' && this.sendEmail){
                    this.showToast('Success', 'PDF Saved and Email Sent!', 'success', 'dismissable');
                }else if(result === 'Success' && !this.sendEmail){
                    this.showToast('Success', 'PDF Saved!', 'success', 'dismissable');
                }else{
                    this.showToast('Error', result, 'error', 'dismissable');
                }

                if(result === 'Success'){
                    this.sendEmail = false;
                    this.body = '';
                    this.selectedFolder = '';
                    this.selectedTemplate = '';
                    this.selectedSignature = '';
                    this.selectedBlock = '';
                    this.selectedEmail = '';
                    this.selectedEmailsList = [];
                    this.ccFaculty = false;
                    this.sendCcEmail = false;
                    this.facultyEmail = '';
                    console.log('sendEmail after save: ' + this.sendEmail);
                    //window.setTimeout(location.reload(), 50000);
                }
            })
            .catch(error => {
                this.hideSpinner();
                this.errorStatus = true;
                this.errorMessage = error.body.message;
                console.log('ERROR: ' + JSON.stringify(error));
                this.showToast('Error', this.errorMessage, 'error', 'pester')
            })
        }                     
    }

    cancel() {
        this.body = '';
        this.body2 = '';
        this.selectedTemplate = '';
        this.selectedFolder = '';
        this.selectedSignature = '';
    }

    closeModal() {
        this.showModal = false;
    }
    
    checkSendStudentChange(event) {
        this.sendEmail = event.target.checked;   
        this.showEmailModal = event.target.checked;
        this.selectedEmailsList = [];
        if(!event.target.checked) {
            this.selectedEmail = '';            
            this.ccEmail = '';
            this.sendCcEmail = false;
            this.additionalCC = '';
            this.ccFaculty = false;
            this.facultyEmail = '';
        }else{
            this.selectedEmail = this.primaryEmail;
        }
    }

    showSpinner() {
        this.displaySpinner = true;
    }

    hideSpinner() {
        this.displaySpinner = false;
    }
    
    replaceParagraphs(textToReplace) {
        const regex = /<p>/gi;
        const regex2 = /<\/p>/gi;
        // var tempStr1 = textToReplace.replaceAll(regex, '<br>');
        var tempStr1 = textToReplace.replace(/<p>/g, '<br>');
        // var tempStr2 = tempStr1.replaceAll(regex2, '</br>');
        var tempStr2 = tempStr1.replace(/<\/p>/g, '</br>');
        return tempStr2;
    }

    replaceBreaks(textToReplace) {
        const regex = /<br>/gi;
        const regex2 = /<\/br>/gi;
        // var tempStr1 = textToReplace.replaceAll(regex, '<p>');
        var tempStr1 = textToReplace.replace(/<br>/g, '<p>');
        // var tempStr2 = tempStr1.replaceAll(regex2, '</p>');
        var tempStr2 = tempStr1.replace(/<\/br>/g, '</p>');
        return tempStr2;
    }

    replaceDoubleBreak(textToReplace) {
        var temStr1 = textToReplace.replace(/<br><\/br>/g, '</br>');
        return temStr1;

    }

    replaceIndent(textToReplace) {
        var tempStr1 = textToReplace;
        var key = '<p class="ql-indent-';
        var indexOf = tempStr1.indexOf(key);
        while(indexOf != -1) {
            var nextIndex = 1;
            while(tempStr1.charAt(indexOf + (key.length - 1) + nextIndex + 3) != '<'){
                nextIndex += 1;
            }
            tempStr1 = tempStr1.substring(0, indexOf + (key.length - 1) + nextIndex + 3) + '</div>' + tempStr1.substring(indexOf + (key.length - 1) + nextIndex + 3);
            
            //Delete extra break
            var breakIndex = tempStr1.indexOf('</br>', indexOf);
            if(breakIndex != -1) {
                tempStr1 = tempStr1.substring(0, (breakIndex)) + tempStr1.substring(breakIndex + 5);
            }

            var startIndex = (indexOf + key.length + nextIndex);
            var brIndexOf = tempStr1.indexOf('<br>', startIndex);
            var lastTag = tempStr1.indexOf('</br>',  brIndexOf + 1);

            if(brIndexOf != -1 && lastTag != -1 && tempStr1.substring(lastTag-4, lastTag) == '<br>') {
                tempStr1 = tempStr1.substring(0, (brIndexOf - 1) ) + tempStr1.substring(lastTag + 5);
            }

            //Find next key if any
            indexOf = tempStr1.indexOf('<p class="ql-indent-', indexOf + 3 + nextIndex);
        }

        tempStr1 = tempStr1.replace(/<p class="ql-indent-1">/g, '<div style="margin-left:45px; margin-bottom: 0px;">');
        tempStr1 = tempStr1.replace(/<p class="ql-indent-2">/g, '<div style="margin-left:90px; margin-bottom: 0px;">')
        tempStr1 = tempStr1.replace(/<p class="ql-indent-3">/g, '<div style="margin-left:135px; margin-bottom: 0px;">')
        tempStr1 = tempStr1.replace(/<p class="ql-indent-4">/g, '<div style="margin-left:180px; margin-bottom: 0px;">')
        tempStr1 = tempStr1.replace(/<p class="ql-indent-5">/g, '<div style="margin-left:225px; margin-bottom: 0px;">')
        return tempStr1;
    }

    closeEmailModal() {
        this.showEmailModal = false;
    }

    checkEmailChange(event) {
        if(event.target.checked && event.target.label === 'All Student Emails'){
            this.selectedEmailsList = [];
            this.selectedEmailsList.push(event.target.value);
            this.showOtherEmails = false;
        }else if(!event.target.checked && event.target.label === 'All Student Emails'){
            this.selectedEmailsList = [];
            this.selectedEmailsList.push(this.primaryEmail);
        }else if(event.target.checked) {
            this.selectedEmailsList = [];
            this.selectedEmailsList.push(this.primaryEmail);
            this.selectedEmailsList.push(event.target.value);
        }else if (!event.target.checked){
            this.selectedEmailsList.splice(this.selectedEmailsList.indexOf(event.target.value),1);
        }
        this.selectedEmail = this.selectedEmailsList.join(';');
    }  
    
    checkEmailChange2(event) {
        if(!event.target.checked){
            this.showOtherEmails = true;
            this.selectedEmailsList = [];
            this.selectedEmailsList.push(this.primaryEmail);
            this.selectedEmail = this.selectedEmailsList;
        }
    }
    
    onChangeCcFaculty(event) {
        this.ccFaculty = event.target.checked;
    }

    onChangeManualCC(event) {
        this.additionalCC = event.target.value;
        if(event.target.value !== null){
            this.sendCcEmail = true;
        }
    }
}