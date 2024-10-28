public with sharing class ShowSOandSOIcontroller {
    @AuraEnabled
    public static List<Sales_Order__c> getSalesOrders(Id opportunityId) {
        return [
            SELECT Id, Name, Total_Amount__c, Discount__c, Total_Devices__c,
                (SELECT Id, Name, Device__c, Amount__c, Discount__c, Final_Amount__c 
                 FROM Sales_Order_Items__r) 
            FROM Sales_Order__c 
            WHERE Opportunity__c = :opportunityId
        ];

    }
}