import { LightningElement } from 'lwc';

export default class HooksExamples extends LightningElement {

    name = 'Robert ';
    constructor() {
        super();
        console.log(' Inside constructor');
        this.name = this.name + ' Jaramillo';
    }

    connectedCallback() {
        console.log(' connectedCallback ');
    }

    disconnectedCallback() {
        console.log(' disconnectedCallback ');
    }

    renderedCallback() {
        console.log(' renderedCallback ');
    }

    /*render() {
        return 
    }*/

    errorCallback(error, stack) {
        console.error(error);
    }
}