public with sharing class ContractController {
    public Devices_Contract__c contract { get; set; }
    
    public String buyerName { get; private set; }
    public String buyerShippingStreet { get; private set; }
    public String buyerShippingCity { get; private set; }
    public String buyerShippingPostalCode { get; private set; }
    public String buyerShippingCountry { get; private set; }

    public List<Device__c> devices { get; private set; }
    
    public String redMedAddress { get; private set; }

    public ContractController(ApexPages.StandardController controller) {
        this.contract = [
            SELECT Id, Account__c, Total_Amount__c 
            FROM Devices_Contract__c 
            WHERE Id = :controller.getId() 
            LIMIT 1
        ];
        
        Account account = [
            SELECT Name, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingCountry 
            FROM Account 
            WHERE Id = :contract.Account__c
            LIMIT 1
        ];
        buyerName = account.Name;
        buyerShippingStreet = account.ShippingStreet;
        buyerShippingCity = account.ShippingCity;
        buyerShippingPostalCode = account.ShippingPostalCode;
        buyerShippingCountry = account.ShippingCountry;
        
        devices = [
            SELECT Name__c, Name, Default_Price__c 
            FROM Device__c 
            WHERE Devices_Contract__c = :contract.Id
        ];

        Stock_Address__mdt redMedAddressRecord = [
            SELECT Stock_Street__c, Stock_City__c, Stock_Country__c, Stock_Postal_Code__c 
            FROM Stock_Address__mdt 
            LIMIT 1
        ];
        redMedAddress = redMedAddressRecord.Stock_Street__c + ', ' +
                        redMedAddressRecord.Stock_City__c + ', ' +
                        redMedAddressRecord.Stock_Postal_Code__c + ', ' +
                        redMedAddressRecord.Stock_Country__c;
    }
}
