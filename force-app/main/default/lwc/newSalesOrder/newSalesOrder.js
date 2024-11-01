import { LightningElement, wire, api } from 'lwc';
import getAvailableDevices from '@salesforce/apex/newSalesOrderController.getAvailableDevices';
import createSalesOrderAndItems from '@salesforce/apex/newSalesOrderController.createSalesOrderAndItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SalesOrder extends LightningElement {
    @api recordId; 
    availableDevices = [];
    orderItems = [];
    orderDiscount = 0;
    totalAmount = 0;
    
    connectedCallback() {
        this.fetchDevices();
    }

    fetchDevices() {
        getAvailableDevices().then(data => {
            this.availableDevices = data.map(device => {
                return { label: device.Name, value: device.Id, price: device.Default_Price__c };
            });
        }).catch(error => {
            this.showToast('Error', 'Failed to fetch devices', 'error');
        });
    }

    handleAddOrderItem() {
        this.orderItems = [...this.orderItems, { deviceId: '', discount: 0, amount: 0 }];
    }

    handleDeviceChange(event) {
        const index = event.target.dataset.index;
        const deviceId = event.detail.value;
        const device = this.availableDevices.find(dev => dev.value === deviceId);
        this.orderItems[index] = { ...this.orderItems[index], deviceId, price: device.price };
        this.calculateAmount(index);
        // this.handleAddOrderItem();
    }

    handleDiscountChange(event) {
        const index = event.target.dataset.index;
        const discount = Math.min(event.detail.value, 99); 
        this.orderItems[index].discount = discount;
        this.calculateAmount(index);
    }

    handleDiscountChangeTotal(event){
        const discount = Math.min(event.detail.value, 99);
        this.orderDiscount = discount;
        this.calculateTotal();
    }

    calculateAmount(index) {
        const item = this.orderItems[index];
        const discountFactor = (100 - item.discount) / 100;
        item.amount = item.price * discountFactor;
        this.calculateTotal();
    }

    calculateTotal() {
        this.totalAmount = this.orderItems.reduce((acc, item) => acc + item.amount, 0) * (1 - this.orderDiscount / 100);
    }

    handleCreateOrder() {
        if (this.orderItems.length === 0) {
            this.showToast('Error', 'Cannot create Sales Order without items', 'error');
            return 1;
        }

        const items = this.orderItems.map(item => ({
            deviceId: item.deviceId,
            price: item.price,
            discount: item.discount
        }));

        createSalesOrderAndItems({ 
            opportunityId: this.recordId, 
            orderDiscount: this.orderDiscount, 
            items: items 
        }).then(() => {
            this.showToast('Success', 'Sales Order created successfully', 'success');
        }).catch(error => {
            this.showToast('Error', 'Failed to create Sales Order', 'error');
        });
    }

    handleCancel() {
        this.orderItems = []; 
        this.orderDiscount = 0;
        this.totalAmount = 0;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
