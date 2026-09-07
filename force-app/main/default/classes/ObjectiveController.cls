public with sharing class ObjectiveController {

    @AuraEnabled(cacheable=true)
    public static List<Objective__c> getObjectives() {

        return [
            SELECT Id,
                   Name,
                   Assigned_User__c,
                   Assigned_User__r.Name,
                   Objective_Year__c
            FROM Objective__c
            ORDER BY Objective_Year__c DESC, Name ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Key_Result__c> getKeyResults(Id objectiveId) {

        List<Key_Result__c> keyResults = [
            SELECT Id,
                   Name,
                   Objective__c,
                   Target__c,
                   Completed_Target__c,
                   Measurement_Type__c,
                   Measurement_Criteria__c
            FROM Key_Result__c
            WHERE Objective__c = :objectiveId
            ORDER BY Name ASC
        ];

        Set<Id> callKeyResultIds = new Set<Id>();
        Set<Id> eventKeyResultIds = new Set<Id>();
        Set<Id> opportunityKeyResultIds = new Set<Id>();
        Set<Id> contractKeyResultIds = new Set<Id>();
        Set<Id> leadKeyResultIds = new Set<Id>();

        Map<Id, String> contractCriteriaByKeyResult =
            new Map<Id, String>();

        for (Key_Result__c keyResult : keyResults) {

            if (keyResult.Measurement_Type__c == 'Calls') {
                callKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Events') {
                eventKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Opportunities') {
                opportunityKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Contracts') {
                contractKeyResultIds.add(keyResult.Id);

                contractCriteriaByKeyResult.put(
                    keyResult.Id,
                    keyResult.Measurement_Criteria__c
                );
            }

            if (keyResult.Measurement_Type__c == 'Leads') {
                leadKeyResultIds.add(keyResult.Id);
            }
        }

        if (!callKeyResultIds.isEmpty()) {

            Map<Id, Integer> callCounts = new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalCalls
                FROM Task
                WHERE TaskSubtype = 'Call'
                AND Status = 'Completed'
                AND Key_Result__c IN :callKeyResultIds
                GROUP BY Key_Result__c
            ]) {

                callCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalCalls')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (callCounts.containsKey(keyResult.Id)) {
                    keyResult.Completed_Target__c =
                        callCounts.get(keyResult.Id);
                } else {
                    keyResult.Completed_Target__c = 0;
                }
            }
        }

        if (!eventKeyResultIds.isEmpty()) {

            Map<Id, Integer> eventCounts = new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalEvents
                FROM Event
                WHERE Key_Result__c IN :eventKeyResultIds
                AND ActivityDate <= :Date.today()
                GROUP BY Key_Result__c
            ]) {

                eventCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalEvents')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Events') {

                    if (eventCounts.containsKey(keyResult.Id)) {
                        keyResult.Completed_Target__c =
                            eventCounts.get(keyResult.Id);
                    } else {
                        keyResult.Completed_Target__c = 0;
                    }
                }
            }
        }

        if (!opportunityKeyResultIds.isEmpty()) {

            Map<Id, Integer> opportunityCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalOpportunities
                FROM Opportunity
                WHERE Key_Result__c IN :opportunityKeyResultIds
                AND StageName = 'Closed Won'
                GROUP BY Key_Result__c
            ]) {

                opportunityCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalOpportunities')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Opportunities') {

                    if (opportunityCounts.containsKey(keyResult.Id)) {
                        keyResult.Completed_Target__c =
                            opportunityCounts.get(keyResult.Id);
                    } else {
                        keyResult.Completed_Target__c = 0;
                    }
                }
            }
        }

        if (!contractKeyResultIds.isEmpty()) {

            Map<Id, Integer> contractCounts =
                new Map<Id, Integer>();

            for (Contract contractRecord : [
                SELECT Id,
                       Key_Result__c,
                       Contract_Type__c
                FROM Contract
                WHERE Key_Result__c IN :contractKeyResultIds
                AND Status = 'Activated'
            ]) {

                String criteria =
                    contractCriteriaByKeyResult.get(
                        contractRecord.Key_Result__c
                    );

                if (
                    criteria == 'All' ||
                    criteria == contractRecord.Contract_Type__c
                ) {

                    Integer currentCount =
                        contractCounts.containsKey(
                            contractRecord.Key_Result__c
                        )
                        ? contractCounts.get(
                            contractRecord.Key_Result__c
                        )
                        : 0;

                    contractCounts.put(
                        contractRecord.Key_Result__c,
                        currentCount + 1
                    );
                }
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Contracts') {

                    if (contractCounts.containsKey(keyResult.Id)) {
                        keyResult.Completed_Target__c =
                            contractCounts.get(keyResult.Id);
                    } else {
                        keyResult.Completed_Target__c = 0;
                    }
                }
            }
        }

        if (!leadKeyResultIds.isEmpty()) {

            Map<Id, Integer> leadCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalLeads
                FROM Lead
                WHERE Key_Result__c IN :leadKeyResultIds
                AND LeadSource = 'Web'
                GROUP BY Key_Result__c
            ]) {

                leadCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalLeads')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Leads') {

                    if (leadCounts.containsKey(keyResult.Id)) {
                        keyResult.Completed_Target__c =
                            leadCounts.get(keyResult.Id);
                    } else {
                        keyResult.Completed_Target__c = 0;
                    }
                }
            }
        }

        return keyResults;
    }
}