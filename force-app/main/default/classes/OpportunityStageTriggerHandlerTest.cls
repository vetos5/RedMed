 @isTest
 private class OpportunityStageTriggerHandlerTest {
    
    static Account potentialAccount;
    
    @testSetup static void setup(){
        potentialAccount = TestDataFactory.createAccountTest('Potential Account', 'Potential Account', false);
        insert potentialAccount;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++){
            Opportunity testOpp = TestDataFactory.createOpportunityTest(potentialAccount, 'Prospecting', false);
            opps.add(testOpp);
        }
        insert opps;

        List<Sales_Order__c> orders = new List<Sales_Order__c>();
        for (Opportunity opp : opps) {
            Sales_Order__c order = TestDataFactory.createSalesOrderTest(opp, false);
            orders.add(order);
        }
        insert orders;

        List<Device__c> devices = new List<Device__c>();
        for (Opportunity opp : opps) {
            Device__c device = TestDataFactory.createDeviceTest(orders[0], potentialAccount);
            devices.add(device);
        }
        insert devices;

        List<Sales_Order_Item__c> items = new List<Sales_Order_Item__c>();
        for (Device__c device : devices) {
            Sales_Order_Item__c item = TestDataFactory.createSalesOrderItemsTest(orders[0].Id, 1000, 10, devices[0], false);
            items.add(item);
        }
        insert items;
    }

    @isTest
    static void testHandleClosedWonOpportunities() {
        Id existingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Existing_Account').getRecordTypeId();
    

        List <Opportunity> oppsToUpdate = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Prospecting'];

        for (Opportunity opp : oppsToUpdate) {
            opp.StageName = 'Negotiation/Review';
        }
        update oppsToUpdate;

        List <Opportunity> oppsToUpdate2 = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Negotiation/Review'];

        for (Opportunity opp : oppsToUpdate2) {
            opp.StageName = 'Closed Won';
        }
        update oppsToUpdate2;

        List <Account> accs = [
            SELECT Id, RecordTypeId 
            FROM Account];

        for (Account acc : accs) {
            System.assertEquals(existingAccountRecordTypeId, acc.RecordTypeId, 'Record Type should be changed to Existing Account');
        }
    }

    @isTest
    static void testCreateContract() {
        List <Opportunity> oppsToUpdate = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Prospecting'];

        for (Opportunity opp : oppsToUpdate) {
            opp.StageName = 'Negotiation/Review';
        }
        update oppsToUpdate;

        List <Opportunity> oppsToUpdate2 = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Negotiation/Review'];

        for (Opportunity opp : oppsToUpdate2) {
            opp.StageName = 'Closed Won';
        }
        update oppsToUpdate2;

        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : oppsToUpdate2) {
            opportunityIds.add(opp.Id);
        }

        List<Opportunity> oppsForContract = [
            SELECT Id, StageName, AccountId
            FROM Opportunity 
            WHERE Id IN :opportunityIds];

        List<Devices_Contract__c> contracts = [
            SELECT Id, Account__c, Region__c, Opportunity__c, Total_Sales_Orders__c, Total_Sales_Order_Items__c, Total_Amount__c, Sold_Date_Time__c 
            FROM Devices_Contract__c
            WHERE Opportunity__c IN :oppsForContract];

        List<Sales_Order__c> orders = [
            SELECT Id, Devices_Contract__c
            FROM Sales_Order__c 
            WHERE Opportunity__c IN :opportunityIds];

        System.assertEquals(200, contracts.size(), '200 contracts should be created');

        for (Devices_Contract__c contract : contracts) {
            System.assertNotEquals(null, contract.Account__c, 'Account should not be null');
            System.assertNotEquals(null, contract.Region__c, 'Region should not be null');
            System.assertNotEquals(null, contract.Opportunity__c, 'Opportunity should not be null');
            System.assertNotEquals(null, contract.Total_Sales_Orders__c, 'Total Sales Orders should not be null');
            System.assertNotEquals(null, contract.Total_Sales_Order_Items__c, 'Total Sales Order Items should not be null');
            System.assertNotEquals(null, contract.Total_Amount__c, 'Total Amount should not be null');
            System.assertNotEquals(null, contract.Sold_Date_Time__c, 'Sold Date Time should not be null');
        }

        for (Sales_Order__c order : orders) {
            System.assertNotEquals(null, order.Devices_Contract__c, 'Contract should be related to the order');
        }
    }

    //in dev
    @isTest
    static void testUpdateDeviceOrderItems() {

        Account acc = [
            SELECT Id, RecordTypeId, ShippingStreet, ShippingCity, ShippingPostalCode 
            FROM Account 
            LIMIT 1
        ];

        List<Devices_Contract__c> contracts = new List<Devices_Contract__c>();
        for (Devices_Contract__c contract : contracts) {
            Devices_Contract__c devContract = TestDataFactory.createContractTest(acc, false);
            contracts.add(devContract);
        }
        insert contracts;

        List <Opportunity> oppsToUpdate = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Prospecting'];

        for (Opportunity opp : oppsToUpdate) {
            opp.StageName = 'Negotiation/Review';
        }
        update oppsToUpdate;

        List <Opportunity> oppsToUpdate2 = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE StageName = 'Negotiation/Review'];

        for (Opportunity opp : oppsToUpdate2) {
            opp.StageName = 'Closed Won';
        }
        update oppsToUpdate2;

        System.debug('DEBUG ACCS: ' + acc);
        
        List<Device__c> updatedDevices = [
            SELECT Id, Account__c, Status__c, RecordTypeId, Address_to_Deliver__Street__s,
            Address_to_Deliver__City__s, Address_to_Deliver__PostalCode__s,
            Devices_Contract__r.Id, Devices_Contract__r.Opportunity__c
            FROM Device__c
            WHERE Account__c = :acc.Id];

        Id soldRecordTypeId = Schema.SObjectType.Device__c.getRecordTypeInfosByDeveloperName().get('Sold').getRecordTypeId();

        for (Device__c device : updatedDevices) {
        System.assertEquals(acc.Id, device.Account__c, 'Account should be updated.');
        System.assertEquals(soldRecordTypeId, device.RecordTypeId, 'Record Type should be updated.');
        System.assertEquals(oppsToUpdate2[0].Id, device.Devices_Contract__r.Opportunity__c, 'Contract should be updated.');
        //System.assertEquals('Sold', device.Status__c, 'Device status should be set to Sold.');
        System.assertEquals(acc.ShippingStreet, device.Address_to_Deliver__Street__s, 'Street address should match.');
        System.assertEquals(acc.ShippingCity, device.Address_to_Deliver__City__s, 'City should match.');
        System.assertEquals(acc.ShippingPostalCode, device.Address_to_Deliver__PostalCode__s, 'Postal code should match.');
        }
    }
}

