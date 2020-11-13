import { LightningElement } from 'lwc';

export default class ParentComp extends LightningElement {
    name = 'Robert ';
    constructor() {
        super();
        console.log(' Inside constructor in Parent');
        this.name = this.name + ' Jaramillo';
    }

    connectedCallback() {
        console.log(' connectedCallback in Parent ');
    }

    disconnectedCallback() {
        console.log(' disconnectedCallback in Parent ');
    }

    /*render() {
        return 
    }*/

    renderedCallback() {
        console.log(' renderedCallback in Parent ');
    }

    errorCallback(error, stack) {
        console.error(error);
    }

    handleSimpleEvent(event) {
        /*const message = event.detail.message;
        const pageNumber = event.detail.pagenumber;
        const name = event.detail.staticVal;
        console.log(' Message is ' + message);
        console.log(' Page Number is ' + pageNumber);
        console.log(' Name is ' + name);*/
        console.log(' Message is ' + event.target.message);
        console.log(' Page Num is ' + event.target.pagenumber);
    }
}