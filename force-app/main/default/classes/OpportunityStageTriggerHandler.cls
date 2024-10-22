public class OpportunityStageTriggerHandler {
    
    public static void run() {
        System.debug('Trigger run method executed.');
        
        if (Trigger.isAfter && Trigger.isUpdate) {
            handleClosedWonOpportunities(
                Trigger.new,
                Trigger.oldMap
            );
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
        
        System.debug('Creating Contracts');
        createContracts(newOpps);

        // updateDeviceOrderItems(newOpps); // Commented out to avoid redundancy
        //createContracts(newOpps);
    }
    
    public static void createContracts(List<SObject> newOpps) {
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
        
        Set<Id> createdOppIds = new Set<Id>();

        for (Opportunity opp : newCastedOpps) {
              if (createdOppIds.contains(opp.Id)) {
            continue; 
        }
            Devices_Contract__c newContract = new Devices_Contract__c();
            
            newContract.Account__c = opp.AccountId;
            newContract.Region__c = accounts.get(opp.AccountId).Region__c;
            newContract.Opportunity__c = opp.Id;
            
            List<Sales_Order__c> relatedOrders = oppToSalesOrders.get(opp.Id);
            newContract.Total_Sales_Orders__c = relatedOrders.size();
            
            Integer totalItems = 0;
            Decimal totalAmount = 0;
            
            for (Sales_Order__c order : relatedOrders) {
                totalItems += order.Total_Devices__c != null ? order.Total_Devices__c.intValue() : 0;
                totalAmount += order.Total_Amount__c != null ? order.Total_Amount__c : 0;
            }
            
            newContract.Total_Sales_Order_Items__c = totalItems;
            newContract.Total_Amount__c = totalAmount;
            newContract.Sold_Date_Time__c = System.now();
            
            contractsToInsert.add(newContract);
            createdOppIds.add(opp.Id);
        }
        
        try {
            insert contractsToInsert;
            System.debug('Created Contracts: ' + contractsToInsert);
        } catch (DmlException e) {
            System.debug('Error creating Contracts: ' + e.getMessage());
        }
    }
    
    
}