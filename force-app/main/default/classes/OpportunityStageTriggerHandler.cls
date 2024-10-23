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
    
    //in dev
    private static void updateDeviceOrderItems(List<SObject> newOpps) {
        Id soldRecordTypeId = Schema.SObjectType.Device__c.getRecordTypeInfosByDeveloperName().get('Sold').getRecordTypeId();
        
        System.debug('Updating device order items...');
        
        List<Sales_Order__c> salesOrders = [
            SELECT Id
            FROM Sales_Order__c
            WHERE Opportunity__c IN :newOpps
        ];
    
        System.debug('Sales Orders related to Opportunities: ' + salesOrders);
    
        List<Sales_Order_Item__c> orderItems = [
            SELECT Id, Sales_Order__c, Device__c
            FROM Sales_Order_Item__c
            WHERE Sales_Order__c IN :salesOrders
            AND Device__c != null
        ];
    
        System.debug('Order Items: ' + orderItems);
    
        Set<Id> deviceIds = new Set<Id>();
        for (Sales_Order_Item__c orderItem : orderItems) {
            deviceIds.add(orderItem.Device__c);
        }
    
        System.debug('Device IDs: ' + deviceIds);
    
        List<Device__c> devicesToUpdate = [
            SELECT Id, Devices_Contract__r.Account__r.ShippingStreet, Devices_Contract__r.Account__c, Status__c, RecordTypeId
            FROM Device__c
            WHERE Id IN :deviceIds
        ];

        System.debug('Devices to Update: ' + devicesToUpdate);

        List<Devices_Contract__c> contracts = [
            SELECT Id, Account__c, Region__c
            FROM Devices_Contract__c
            WHERE Account__c IN :deviceIds
        ];

        System.debug('CONTRACTS: ' + contracts);
        
        Set<Device__c> deviceSetToUpdate = new Set<Device__c>();
        for (Sales_Order_Item__c orderItem : orderItems) {
            for (Device__c device : devicesToUpdate) {
                if (device.Id == orderItem.Device__c) {

                    system.debug('Device found: ' + device);
                    device.Status__c = 'Sold';
                    device.RecordTypeId = soldRecordTypeId;
                    device.Account__c = device.Devices_Contract__r.Account__c;
                    device.Address_to_Deliver__Street__s = device.Devices_Contract__r.Account__r.ShippingStreet;
                    deviceSetToUpdate.add(device);
                    system.debug('DEVICE UPDATED!: ' + device); 
                }
            }
        }
    
        if (!deviceSetToUpdate.isEmpty()) { 
            try {
                update new List<Device__c>(deviceSetToUpdate);
                System.debug('Updated Device Order Items: ' + deviceSetToUpdate);
            } catch (DmlException e) {
                System.debug('Error updating Device Order Items: ' + e.getMessage());
            }
        } else {
            System.debug('No Device Order Items found for update.');
        }
    }
} 