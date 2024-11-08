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

    handlePrevious: function (component, event, helper) {
        let offset = component.get('v.offset') - component.get('v.limit');
        component.set('v.offset', offset > 0 ? offset : 0);
        helper.fetchSalesOrders(component);
    },

    handleNext: function (component, event, helper) {
        console.log('handleNext');
        let offset = component.get('v.offset') + component.get('v.limit');
        component.set('v.offset', offset);
        helper.fetchSalesOrders(component);
    }

})
