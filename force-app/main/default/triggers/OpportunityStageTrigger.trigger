trigger OpportunityStageTrigger on Opportunity (before update, after update, before insert, after insert) {
    OpportunityStageTriggerHandler.run();
}
