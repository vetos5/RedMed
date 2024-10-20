@isTest
private class OpportunityStageTriggerHandlerTest {
    @isTest
    static void testHandleClosedWonOpportunities() {
        Account potentialAccount = OpportunityStageTriggerHandlerTestData.createAccount('Potential Account', 'Potential_Account');
        
        List<Account> accs = new List<Account>();
        accs.add(potentialAccount);

        Set<Id> accIds = new Set<Id> ();

        for (Account acc : accs){
            accIds.add(acc.Id);
        }
        

        Opportunity negotiationOpportunity = OpportunityStageTriggerHandlerTestData.createOpportunity(potentialAccount, 'Negotiation/Review');
        
        negotiationOpportunity.StageName = 'Closed Won';
        update negotiationOpportunity;

        Sales_Order__c order = new Sales_Order__c(
            Opportunity__c = negotiationOpportunity.Id
        );

        List<Sales_Order_Item__c> items = new List<Sales_Order_Item__c>();
        for(Integer i = 1; i < 6; i++){
            Sales_Order_Item__c item = new Sales_Order_Item__c(
                Amount__c = i*1000,
                Discount__c = i,
                Sales_Order__c = order.Id
            );
            items.add(item);
        }

        Account updatedAccount = [
            SELECT Id, RecordTypeId 
            FROM Account 
            WHERE Id = :potentialAccount.Id
            ];

        System.assertEquals(
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Existing_Account').getRecordTypeId(),
            updatedAccount.RecordTypeId,
            'Account Record Type should be updated to Existing Account'
        );
        
        List<Devices_Contract__c> contracts = [
            SELECT Id 
            FROM Devices_Contract__c 
            WHERE Opportunity__c IN: accs
        ];

        System.assertEquals(1, contracts.size(), 'A contract should have been created for the Closed Won opportunity.');
    }

    @isTest
    static void testUpdateDeviceOrderItems(){
        Account potentialAccount = OpportunityStageTriggerHandlerTestData.createAccount('Potential Account', 'Potential_Account');
        
        Opportunity negotiationOpportunity = OpportunityStageTriggerHandlerTestData.createOpportunity(potentialAccount, 'Prospecting');
        Sales_Order__c order = OpportunityStageTriggerHandlerTestData.createSalesOrder(negotiationOpportunity);
        negotiationOpportunity.StageName = 'Negotiation/Review';
        update negotiationOpportunity;
        Devices_Contract__c contract = OpportunityStageTriggerHandlerTestData.createContract(potentialAccount);

        List<Device__c> devices = new List<Device__c>();
        for (Integer i = 0; i < 5; i++) {
            Device__c device = OpportunityStageTriggerHandlerTestData.createDevice(order, potentialAccount, contract);
            devices.add(device);
        }
        insert devices;

        negotiationOpportunity.StageName = 'Closed Won';
        update negotiationOpportunity;

        List<Device__c> updatedDevices = [
            SELECT Id, Status__c, Devices_Contract__c 
            FROM Device__c 
            WHERE Account__c = :potentialAccount.Id
        ];

        for (Device__c updatedDevice : updatedDevices) {
            System.assertEquals('Sold', updatedDevice.Status__c, 'Device status should be updated to Sold');
            System.assertEquals(contract.Id, updatedDevice.Devices_Contract__c, 'Device should reference the created contract');
        }
    }
}

    
