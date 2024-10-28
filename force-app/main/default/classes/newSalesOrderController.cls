public with sharing class newSalesOrderController {
    @AuraEnabled(cacheable=true)
    public static List<Device__c> getAvailableDevices() {
        return [SELECT Id, Name, Default_Price__c FROM Device__c WHERE Status__c = 'In Stock'];
    }

    @AuraEnabled
    public static void createSalesOrderAndItems(Id opportunityId, Decimal orderDiscount, List<OrderItemWrapper> items) {
        Sales_Order__c salesOrder = new Sales_Order__c(
            Opportunity__c = opportunityId,
            Discount__c = orderDiscount
        );
        insert salesOrder;

        List<Sales_Order_Item__c> orderItems = new List<Sales_Order_Item__c>();
        for (OrderItemWrapper item : items) {
            Decimal finalPrice = item.price * (1 - item.discount / 100);
            Sales_Order_Item__c orderItem = new Sales_Order_Item__c(
                Sales_Order__c = salesOrder.Id,
                Device__c = item.deviceId,
                Discount__c = item.discount,
                Amount__c = finalPrice
            );
            orderItems.add(orderItem);
        }
        insert orderItems;
    }

    public class OrderItemWrapper {
        @AuraEnabled public Id deviceId;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Decimal discount;
    }
}
