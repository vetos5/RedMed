@isTest
public class OpportunityStageTriggerHandlerTestData {
    public static Account createAccount(String name, String recordTypeName) {
        Account acc = new Account(
        Name = name,
        Region__c = 'EMEA');

        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

        insert acc;
        return acc;
    }

    public static Opportunity createOpportunity(Account acc, String stageName) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = stageName,
            CloseDate = Date.today(),
            AccountId = acc.Id
        );

        insert opp;
        return opp;
    }

    public static Sales_Order_Item__c createSalesOrderItems(Id orderId, Decimal amount, Decimal discount) {

        Sales_Order_Item__c item = new Sales_Order_Item__c(
            Amount__c = amount,
            Discount__c = discount,
            Sales_Order__c = orderId
        );
        insert item;
        return item;
    }

    public static Sales_Order__c createSalesOrder(Opportunity opp) {
        Sales_Order__c order = new Sales_Order__c(
            Opportunity__c = opp.Id
        );
        insert order;
        return order;
    }

    public static Devices_Contract__c createContract(Account acc) {
        Devices_Contract__c contract = new Devices_Contract__c(
            Account__c = acc.Id,
            Sold_Date_Time__c = System.now(),
            Region__c = acc.Region__c
        );
        insert contract;
        return contract;
    }

    public static Device__c createDevice(Sales_Order__c order, Account acc, Devices_Contract__c contract) {
        Device__c device = new Device__c(
            Status__c = 'In stock',
            Account__c = acc.Id,
            Devices_Contract__c = contract.Id,
            Name__c = 'Test'
        );

        return device;
    }
}