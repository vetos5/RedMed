public class OpportunityStageTriggerHandler {

    public static void run() {
        System.debug('Trigger run method executed.');

        if (Trigger.isBefore && Trigger.isUpdate) {
            handleClosedWonOpportunities(
                Trigger.new,
                Trigger.oldMap
            );
        }
    }
    
    public static void handleClosedWonOpportunities(List<SObject> newOpps, Map<Id, SObject> oldOpps) {
        System.debug('Handling Closed Won Opportunities');
        
        Id existingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Existing_Account').getRecordTypeId();
        Id potentialAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Potential_Account').getRecordTypeId();

        System.debug('Existing Account Record Type ID: ' + existingAccountRecordTypeId);
        System.debug('Potential Account Record Type ID: ' + potentialAccountRecordTypeId);

        List<Id> accountIdsToUpdate = new List<Id>();
        List<Opportunity> newCastedOpps = (List<Opportunity>)newOpps;

        System.debug('Number of Opportunities to process: ' + newCastedOpps.size());
        
        for (Opportunity opp : newCastedOpps) {
            Opportunity oldCastedOpp = (Opportunity)oldOpps.get(opp.Id); 
            
            if (opp.StageName == 'Closed Won' && oldCastedOpp.StageName != 'Closed Won') {
                if (opp.AccountId != null) {
                    accountIdsToUpdate.add(opp.AccountId);
                    createContract(newCastedOpps);
                }
            }
        }

        if (!accountIdsToUpdate.isEmpty()) {
            try {
                List<Account> accountsToUpdate = [
                    SELECT Id, RecordTypeId 
                    FROM Account 
                    WHERE Id IN :accountIdsToUpdate
                ];

                System.debug('Accounts retrieved for update: ' + accountsToUpdate);

                for (Account acc : accountsToUpdate) {
                    if (acc.RecordTypeId == potentialAccountRecordTypeId) {
                        acc.RecordTypeId = existingAccountRecordTypeId;
                        System.debug('Changing Record Type for Account: ' + acc.Id);
                    }
                }

                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                    System.debug('Updated Accounts: ' + accountsToUpdate);
                }

            } catch (DmlException e) {
                System.debug('Error updating accounts: ' + e.getMessage());
                System.debug('DML Exception stack trace: ' + e.getStackTraceString());
            }
        } else {
            System.debug('No account IDs to update.');
        }

       //updateDeviceOrderItems(newOpps);
    }

    private static void createContract(List<SObject> newOpps) {
        System.debug('Contract creation process started');
        
        List<Opportunity> newCastedOpps = (List<Opportunity>)newOpps;
        
        Set<Id> newOppIds = new Set<Id>();
        for (Opportunity opp : newCastedOpps){
            newOppIds.add(opp.AccountId); 
        }

        Devices_Contract__c newContract = new Devices_Contract__c();
        
        Account account = [
            SELECT Id, Region__c 
            FROM Account 
            WHERE Id IN :newOppIds
            ];

        List<Sales_Order__c> salesOrders = [
            SELECT Id, Total_Amount__c, Total_Devices__c 
            FROM Sales_Order__c 
            WHERE Opportunity__c IN :newCastedOpps
        ];

        for (Opportunity opp : newCastedOpps){
            newContract.Account__c = opp.AccountId; 
            newContract.Region__c = account.Region__c; 
            newContract.Opportunity__c = opp.Id;
    
            newContract.Total_Sales_Orders__c = salesOrders.size();

            Integer totalItems = 0;
            Decimal totalAmount = 0;

            for (Sales_Order__c order : salesOrders) {
                totalItems += order.Total_Devices__c != null ? order.Total_Devices__c.intValue() : 0; 
                totalAmount += order.Total_Amount__c != null ? order.Total_Amount__c : 0;
            }
        
        newContract.Total_Sales_Order_Items__c = totalItems;
        newContract.Total_Amount__c = totalAmount;
        
        }
        newContract.Sold_Date_Time__c = System.now();
    
        try {
            insert newContract;
            System.debug('Created Contract: ' + newContract.Id);
        } catch (DmlException e) {
            System.debug('Error creating Contract: ' + e.getMessage());
        }
    }

    private static void updateDeviceOrderItems(List<SObject> newOpps) {
        Id soldRecordTypeId = Schema.SObjectType.Device__c.getRecordTypeInfosByDeveloperName().get('Sold').getRecordTypeId();
    
         List<Opportunity> newCastedOpps = (List<Opportunity>)newOpps;
    
    Set<Id> newOppIds = new Set<Id>();
    for (Opportunity opp : newCastedOpps){
        newOppIds.add(opp.Id); 
    }  
    
    Set<Id> newOppAccIds = new Set<Id>();
    for (Opportunity opp : newCastedOpps){
        newOppAccIds.add(opp.AccountId); 
    }

    Account account = [
        SELECT Id, Region__c, ShippingCity, ShippingPostalCode, ShippingStreet, ShippingCountry
        FROM Account 
        WHERE Id IN :newOppAccIds
        ];

    Map<Id, Devices_Contract__c> contractsMap = new Map<Id, Devices_Contract__c>();
    for (Devices_Contract__c contract : [
        SELECT Id, (SELECT Id, Account__c, Address_to_Deliver__c, Status__c, RecordTypeId FROM Device__r)
        FROM Devices_Contract__c 
        WHERE Opportunity__c IN :newOppIds
    ]) {
        contractsMap.put(contract.Account__c, contract);
    }

    //map should be here
    
    for (Device__c device : devices) {
        for (Opportunity opp : newCastedOpps) {
                device.Account__c = opp.AccountId;
                device.RecordTypeId = soldRecordTypeId; 
                device.Status__c = 'Sold'; 
                
                if (contractsMap.containsKey(opp.AccountId)) {
                    device.Devices_Contract__c = contractsMap.get(opp.AccountId).Id; 
                }
                
                device.Address_to_Deliver__Street__s = opp.Account.ShippingStreet; 
                device.Address_to_Deliver__City__s = opp.Account.ShippingCity; 
                device.Address_to_Deliver__PostalCode__s = opp.Account.ShippingPostalCode; 
        }
    }
    
        if (!devices.isEmpty()) {
            try {
                update devices;
                System.debug('Updated Device Order Items: ' + devices);
            } catch (DmlException e) {
                System.debug('Error updating Device Order Items: ' + e.getMessage());
            }
        } else {
            System.debug('No Device Order Items found for update.');
        }
    }

