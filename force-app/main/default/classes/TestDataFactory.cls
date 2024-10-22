@isTest
public class TestDataFactory {
    public static Account createAccountTest(String name, String recordTypeName, Boolean isInsert) {
        Account acc = new Account(
        RecordTypeId = '012d2000000r7jJAAQ',       
        Name = name,
        Region__c = 'EMEA',
        ShippingStreet = '10 Downing Street',
        ShippingCity = 'London',
        ShippingPostalCode = 'SW1A 1AA');

        System.debug('Account Record Type ID: ' + acc.RecordTypeId);

        if (isInsert) {
            insert acc;
        }
        return acc;
    }

    public static Opportunity createOpportunityTest(Account acc, String stageName, Boolean isInsert) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = stageName,
            CloseDate = Date.today(),
            AccountId = acc.Id
        );

        if(isInsert) {
            insert opp;
        }
        return opp;
        
    }

    public static Sales_Order_Item__c createSalesOrderItemsTest(Id orderId, Decimal amount, Decimal discount, Device__c device, Boolean isInsert) {
        Sales_Order_Item__c item = new Sales_Order_Item__c(
            Amount__c = amount,
            Discount__c = discount,
            Sales_Order__c = orderId,
            Device__c = device.Id
        );

        if (isInsert) {
            insert item;
        }
        return item; 
    }

    public static Sales_Order__c createSalesOrderTest(Opportunity opp, Boolean isInsert) {
        Sales_Order__c order = new Sales_Order__c(
            Opportunity__c = opp.Id
        );
        
        if (isInsert) {
            insert order;
        }
        return order;
        
    }

    public static Devices_Contract__c createContractTest(Account acc, Boolean isInsert) {
        Devices_Contract__c contract = new Devices_Contract__c(
            Account__c = acc.Id,
            Sold_Date_Time__c = System.now(),
            Region__c = acc.Region__c
        );

        if (isInsert) {
            insert contract;
        }
        return contract;
        
    }

    public static Device__c createDeviceTest(Sales_Order__c order, Account acc) {
        Device__c device = new Device__c(
            Status__c = 'In stock',
            Account__c = acc.Id,
            Name__c = 'Test1'
        );

        return device;
    }
}