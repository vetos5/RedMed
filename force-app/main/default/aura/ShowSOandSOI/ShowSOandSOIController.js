({
    doInit : function(component, event, helper) {
        helper.fetchSalesOrders(component);
    },
    
    navigateToOrder : function(component, event, helper) {
        helper.navigateToOrder(component, event);
    },
    
    navigateToItem : function(component, event, helper) {
        helper.navigateToItem(component, event);
    },

})
