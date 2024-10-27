({
    fetchSalesOrders: function(component) {
        var action = component.get("c.getSalesOrders");
        action.setParams({ opportunityId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var orders = response.getReturnValue();
                component.set("v.salesOrders", orders);
                console.log('Fetched Orders:', orders); 
            } else {
                console.error("Failed to fetch sales orders: " + response.getError());
            }
        });

        $A.enqueueAction(action);
    }
})
