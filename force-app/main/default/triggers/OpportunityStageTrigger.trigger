trigger OpportunityStageTrigger on Opportunity (before update) {
    OpportunityStageTriggerHandler.run();
}
