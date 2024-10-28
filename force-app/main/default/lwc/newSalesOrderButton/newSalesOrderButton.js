import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class newSalesOrderButton extends LightningElement {
    handleButtonClick() {
        const createOrderEvent = new CustomEvent('createorder');
        this.dispatchEvent(createOrderEvent);
    }
}
