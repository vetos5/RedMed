public with sharing class newSalesOrderController {
    @AuraEnabled(cacheable=true)
    public static List<Device__c> getAvailableDevices() {
        return [SELECT Id, Name, Default_Price__c FROM Device__c WHERE Status__c = 'In Stock'];
    }

    @AuraEnabled
    public static void createSalesOrderAndItems(Id opportunityId, Decimal orderDiscount, List<OrderItemWrapper> items) {
        System.debug('GOUDA' + items);
        Sales_Order__c salesOrder = new Sales_Order__c(
            Opportunity__c = opportunityId,
            Discount__c = orderDiscount
        );
        insert salesOrder;
        System.debug('+++++++++++++++++++++++++++++++++++Sales Order created+++++++++++++++++++++++++++++++++++');
        List<Sales_Order_Item__c> orderItems = new List<Sales_Order_Item__c>();
        System.debug('Creating Sales Order Items');
        for (OrderItemWrapper item : items) {
            Sales_Order_Item__c orderItem = new Sales_Order_Item__c(
                Sales_Order__c = salesOrder.Id,
                Device__c = item.deviceId,
                Discount__c = item.discount,
                Amount__c = item.price
            );
            System.debug('Device assigned' + item.deviceId);
            orderItems.add(orderItem);
        }

        insert orderItems;
        system.debug('+++++++++++++++++++++++++++++++++++Items created+++++++++++++++++++++++++++++++++++');
    }

    public class OrderItemWrapper {
        @AuraEnabled public String deviceId {get; set;}
        @AuraEnabled public Decimal price {get; set;}
        @AuraEnabled public Decimal discount {get; set;}
    }
}
