public class OpportunityStageTriggerHandler {
    
    public static void run() {
        System.debug('Trigger run method executed.');
        
        if (Trigger.isAfter && Trigger.isUpdate) {
            handleClosedWonOpportunities(
                Trigger.new,
                Trigger.oldMap
            );
            createContracts(Trigger.new);
            updateDeviceOrderItems(Trigger.new);
        }
        else{
            System.debug('Trigger not supported.');
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
    
    private static void createContracts(List<SObject> newOpps) {
        System.debug('Contract creation process started');
        
        List<Opportunity> newCastedOpps = (List<Opportunity>)newOpps;
        
        Set<Id> newOppIds = new Set<Id>();
        for (Opportunity opp : newCastedOpps) {
            newOppIds.add(opp.AccountId);
        }
        
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, Region__c 
            FROM Account 
            WHERE Id IN :newOppIds
        ]);
        
        List<Sales_Order__c> salesOrders = [
            SELECT Id, Total_Amount__c, Total_Devices__c, Opportunity__c 
            FROM Sales_Order__c 
            WHERE Opportunity__c IN :newCastedOpps
        ];
        
        Map<Id, List<Sales_Order__c>> oppToSalesOrders = new Map<Id, List<Sales_Order__c>>();
        for (Sales_Order__c order : salesOrders) {
            if (!oppToSalesOrders.containsKey(order.Opportunity__c)) {
                oppToSalesOrders.put(order.Opportunity__c, new List<Sales_Order__c>());
            }
            oppToSalesOrders.get(order.Opportunity__c).add(order);
        }
        
        List<Devices_Contract__c> contractsToInsert = new List<Devices_Contract__c>();
        
       
        List<Sales_Order__c> ordersToUpdate = new List<Sales_Order__c>();

        Map<Sales_Order__c, Devices_Contract__c> salesOrderToContractMap = new Map<Sales_Order__c, Devices_Contract__c>();
        for (Opportunity opp : newCastedOpps) {
            if (opp.StageName == 'Closed Won'){
                Devices_Contract__c newContract = new Devices_Contract__c();
            
            newContract.Account__c = opp.AccountId;
            newContract.Region__c = accounts.get(opp.AccountId).Region__c;
            newContract.Opportunity__c = opp.Id;
            
            List<Sales_Order__c> relatedOrders = new List<Sales_Order__c>();
            relatedOrders = oppToSalesOrders.get(opp.Id);
            newContract.Total_Sales_Orders__c = relatedOrders.size();
            
            Integer totalItems = 0;
            Decimal totalAmount = 0;
            
            for (Sales_Order__c order : relatedOrders) {
                totalItems += order.Total_Devices__c != null ? order.Total_Devices__c.intValue() : 0;
                totalAmount += order.Total_Amount__c != null ? order.Total_Amount__c : 0;
                salesOrderToContractMap.put(order, newContract);
            }
            
            newContract.Total_Sales_Order_Items__c = totalItems;
            newContract.Total_Amount__c = totalAmount;
            newContract.Sold_Date_Time__c = System.now();
            
            contractsToInsert.add(newContract);
        }
        }
        
        try {
            insert contractsToInsert;
            for(Sales_Order__c order : salesOrderToContractMap.keySet()) {
                order.Devices_Contract__c = salesOrderToContractMap.get(order).Id;
                ordersToUpdate.add(order);
            }
            update ordersToUpdate;
            System.debug('Created Contracts: ' + contractsToInsert);
        } catch (DmlException e) {
            System.debug('Error creating Contracts: ' + e.getMessage());
        }
    }
    
    private static void updateDeviceOrderItems(List<SObject> newOpps) {
        System.debug('Updating Device Order Items');
    
        Id soldRecordTypeId = Schema.SObjectType.Device__c.getRecordTypeInfosByDeveloperName().get('Sold').getRecordTypeId();
           
        Map<Id, Id> opportunityToAccountMap = new Map<Id, Id>();
        for (SObject s : newOpps) {
            Opportunity opp = (Opportunity)s;
            if (opp.StageName == 'Closed Won') {
                opportunityToAccountMap.put(opp.Id, opp.AccountId);
            }
        }
        
        List<Sales_Order_Item__c> orderItems = [
            SELECT Id, Device__c, Sales_Order__r.Opportunity__c, Sales_Order__r.Devices_Contract__c 
            FROM Sales_Order_Item__c 
            WHERE Sales_Order__r.Opportunity__c IN :opportunityToAccountMap.keySet()
        ];
    
        Set<Id> deviceIds = new Set<Id>();
        for (Sales_Order_Item__c item : orderItems) {
            deviceIds.add(item.Device__c);
        }
    
        List<Device__c> devicesToUpdate = [
            SELECT Id, RecordTypeId, Status__c, Account__c, Address_To_Deliver__c 
            FROM Device__c 
            WHERE Id IN :deviceIds
        ];
    
        List<Device__c> updatedDevices = new List<Device__c>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    
        Set<Id> opportunityIds = new Set<Id>();
        for (Sales_Order_Item__c item : orderItems) {
            if (item.Sales_Order__r.Opportunity__c != null) {
                opportunityIds.add(item.Sales_Order__r.Opportunity__c);
            }
        }

        if (!opportunityIds.isEmpty()) {
            List<Opportunity> relatedOpps = [
                SELECT Id, Account.Id, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry 
                FROM Opportunity 
                WHERE Id IN :opportunityIds
            ];
            for (Opportunity opp : relatedOpps) {
                opportunityMap.put(opp.Id, opp);
            }
        }

        Map<Id, Id> deviceContractMap = new Map<Id, Id>();
            for (Sales_Order_Item__c item : orderItems) {
            if (item.Sales_Order__r.Devices_Contract__c != null) {
                deviceContractMap.put(item.Device__c, item.Sales_Order__r.Devices_Contract__c);
            }
        }

        for (Device__c device : devicesToUpdate) {
             device.Status__c = 'Sold'; 
            device.RecordTypeId = soldRecordTypeId;

            if (deviceContractMap.containsKey(device.Id)) {
                device.Devices_Contract__c = deviceContractMap.get(device.Id);
            }
    
            for (Sales_Order_Item__c item : orderItems) {
                if (item.Device__c == device.Id) {
                    device.Account__c = opportunityToAccountMap.get(item.Sales_Order__r.Opportunity__c);
                    if (opportunityMap.containsKey(item.Sales_Order__r.Opportunity__c)) {
                        Opportunity relatedOpp = opportunityMap.get(item.Sales_Order__r.Opportunity__c);
                        device.Address_to_Deliver__Street__s = relatedOpp.Account.ShippingStreet; 
                        device.Address_to_Deliver__City__s = relatedOpp.Account.ShippingCity;
                        device.Address_to_Deliver__PostalCode__s = relatedOpp.Account.ShippingPostalCode;  
                    }
                    break; 
                }
            }
            updatedDevices.add(device);
        }

        if (!updatedDevices.isEmpty()) {
            try {
                update updatedDevices;
                System.debug('Updated Devices: ' + updatedDevices);
            } catch (DmlException e) {
                System.debug('Error updating Devices: ' + e.getMessage());
            }
        } else {
            System.debug('No Devices to update.');
        }
    }
}   
