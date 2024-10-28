public with sharing class ShowSOandSOIcontroller {
    @AuraEnabled
    public static List<Map<String, Object>> getSalesOrders(Id opportunityId) {

        System.debug('Fetching Sales Orders for Opportunity Id: ' + opportunityId);

        List<Map<String, Object>> salesOrdersList = new List<Map<String, Object>>();
        
        List<Sales_Order__c> salesOrders = [
            SELECT Id, Name,
                (SELECT Id, Name, Device__c, Amount__c, Discount__c, Final_Amount__c 
                 FROM Sales_Order_Items__r) 
            FROM Sales_Order__c 
            WHERE Opportunity__c = :opportunityId
        ];
        
        for (Sales_Order__c order : salesOrders) {
            Map<String, Object> orderMap = new Map<String, Object>();
            orderMap.put('Id', order.Id);
            orderMap.put('Name', order.Name);
            
            List<Map<String, Object>> orderItemsList = new List<Map<String, Object>>();
            for (Sales_Order_Item__c item : order.Sales_Order_Items__r) {
                Map<String, Object> itemMap = new Map<String, Object>();
                itemMap.put('Id', item.Id);
                itemMap.put('Name', item.Name);
                itemMap.put('Device', item.Device__c);
                itemMap.put('Amount', item.Amount__c);
                itemMap.put('Discount', item.Discount__c);
                itemMap.put('FinalAmount', item.Final_Amount__c);
                orderItemsList.add(itemMap);
            }
            orderMap.put('OrderItems', orderItemsList);
            salesOrdersList.add(orderMap);
        }
        
        System.debug('Sales Orders Fetching Finished: ' + salesOrdersList);
        return salesOrdersList;
    }
}