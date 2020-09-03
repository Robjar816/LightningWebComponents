import { LightningElement } from 'lwc';

export default class ContactList extends LightningElement {
    contacts = [
        {
            Id : 1,
            Name : 'Robert Jaramillo',
            Email : 'robjar816@gmail.com',
            Phone : '9876543210'
        },
        {
            Id : 2,
            Name : 'John Doe',
            Email : 'john.doe@gmail.com',
            Phone : '9876543210'
        },
        {
            Id : 3,
            Name : 'Andrew John',
            Email : 'andrew.john@gmail.com',
            Phone : '9876543210'
        }
    ];
}