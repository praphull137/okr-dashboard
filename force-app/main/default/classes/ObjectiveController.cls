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
        Set<Id> surveyKeyResultIds = new Set<Id>();
        Set<Id> reviewKeyResultIds = new Set<Id>();
        Set<Id> googleReviewKeyResultIds = new Set<Id>();
        Set<Id> caseStudyKeyResultIds = new Set<Id>();

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

            if (keyResult.Measurement_Type__c == 'Surveys') {
                surveyKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Reviews') {
                reviewKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Google Reviews') {
                googleReviewKeyResultIds.add(keyResult.Id);
            }

            if (keyResult.Measurement_Type__c == 'Case Studies') {
                caseStudyKeyResultIds.add(keyResult.Id);
            }
        }

        /*
         * CALLS
         */
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

                if (keyResult.Measurement_Type__c == 'Calls') {

                    keyResult.Completed_Target__c =
                        callCounts.containsKey(keyResult.Id)
                        ? callCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * EVENTS
         */
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

                    keyResult.Completed_Target__c =
                        eventCounts.containsKey(keyResult.Id)
                        ? eventCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * OPPORTUNITIES
         */
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

                    keyResult.Completed_Target__c =
                        opportunityCounts.containsKey(keyResult.Id)
                        ? opportunityCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * CONTRACTS
         */
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

                    keyResult.Completed_Target__c =
                        contractCounts.containsKey(keyResult.Id)
                        ? contractCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * WEB LEADS
         */
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

                    keyResult.Completed_Target__c =
                        leadCounts.containsKey(keyResult.Id)
                        ? leadCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * SURVEYS
         */
        if (!surveyKeyResultIds.isEmpty()) {

            Map<Id, Integer> surveyCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalSurveys
                FROM OKR_Survey__c
                WHERE Key_Result__c IN :surveyKeyResultIds
                GROUP BY Key_Result__c
            ]) {

                surveyCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalSurveys')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Surveys') {

                    keyResult.Completed_Target__c =
                        surveyCounts.containsKey(keyResult.Id)
                        ? surveyCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * REVIEWS
         */
        if (!reviewKeyResultIds.isEmpty()) {

            Map<Id, Integer> reviewCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalReviews
                FROM OKR_Review__c
                WHERE Key_Result__c IN :reviewKeyResultIds
                GROUP BY Key_Result__c
            ]) {

                reviewCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalReviews')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Reviews') {

                    keyResult.Completed_Target__c =
                        reviewCounts.containsKey(keyResult.Id)
                        ? reviewCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        /*
         * GOOGLE REVIEWS
         */
        if (!googleReviewKeyResultIds.isEmpty()) {

            Map<Id, Integer> googleReviewCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalGoogleReviews
                FROM OKR_Google_Review__c
                WHERE Key_Result__c IN :googleReviewKeyResultIds
                GROUP BY Key_Result__c
            ]) {

                Id keyResultId =
                    (Id) result.get('keyResultId');

                Integer totalReviews =
                    (Integer) result.get('totalGoogleReviews');

                googleReviewCounts.put(
                    keyResultId,
                    totalReviews
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Google Reviews') {

                    Integer completed =
                        googleReviewCounts.containsKey(keyResult.Id)
                        ? googleReviewCounts.get(keyResult.Id)
                        : 0;

                    keyResult.Completed_Target__c = completed;
                }
            }
        }

        /*
         * CASE STUDIES
         */
        if (!caseStudyKeyResultIds.isEmpty()) {

            Map<Id, Integer> caseStudyCounts =
                new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Key_Result__c keyResultId,
                       COUNT(Id) totalCaseStudies
                FROM OKR_Case_Study__c
                WHERE Key_Result__c IN :caseStudyKeyResultIds
                GROUP BY Key_Result__c
            ]) {

                caseStudyCounts.put(
                    (Id) result.get('keyResultId'),
                    (Integer) result.get('totalCaseStudies')
                );
            }

            for (Key_Result__c keyResult : keyResults) {

                if (keyResult.Measurement_Type__c == 'Case Studies') {

                    keyResult.Completed_Target__c =
                        caseStudyCounts.containsKey(keyResult.Id)
                        ? caseStudyCounts.get(keyResult.Id)
                        : 0;
                }
            }
        }

        return keyResults;
    }
}