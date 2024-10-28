({
    
    navigateToOrder : function(component, event, helper) {
        var orderId = event.currentTarget.dataset.orderId;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": orderId });
        navEvt.fire();
    },

    navigateToItem : function(component, event, helper) {
        var itemId = event.currentTarget.dataset.itemId;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": itemId });
        navEvt.fire();
    },

    fetchSalesOrders: function(component) {
        var action = component.get("c.getSalesOrders");
        action.setParams({ opportunityId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var orders = response.getReturnValue();
                console.log('Sales Orders:', orders); 
                component.set("v.salesOrders", orders);
            } else {
                console.error("Failed to fetch sales orders: ", response.getError());
            }
        });

        $A.enqueueAction(action);
    }
})
