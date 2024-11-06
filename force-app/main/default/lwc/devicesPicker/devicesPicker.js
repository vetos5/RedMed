import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = [
   'Device__c.Name__c',
   'Device__c.Default_Price__c',
]
 
export default class ContactsLightningRecordPicker extends LightningElement {
   @track deviceId;
 
   filter = {
    criteria: [
        {
            fieldPath: 'Status__c',
            operator: 'eq',
            value: 'In Stock',
        },
        {
            fieldPath: 'Order_Is_Pending__c',
            operator: 'eq',
            value: false,
        }
    ],
    filterLogic: '1 AND 2',
};
 
   @wire(getRecord, { recordId: '$deviceId', fields: FIELDS })
   device;
 
 
   handleRecordChange(event) {
       this.deviceId = event.detail.recordId;
   }
}