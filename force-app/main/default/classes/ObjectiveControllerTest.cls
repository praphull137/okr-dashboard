@IsTest
private class ObjectiveControllerTest {
    private static String getFirstPicklistValue(
        Schema.SObjectField field
    ) {
        for (
            Schema.PicklistEntry entry :
            field.getDescribe().getPicklistValues()
        ) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return null;
    }


    @IsTest
    static void testGetObjectives() {

        Objective__c testObjective = new Objective__c(
            Name = 'Test Objective',
            Assigned_User__c = UserInfo.getUserId(),
            Objective_Year__c = 2026
        );

        insert testObjective;

        Test.startTest();

        List<Objective__c> results =
            ObjectiveController.getObjectives();

        Test.stopTest();

        System.assertEquals(1, results.size());

        System.assertEquals(
            'Test Objective',
            results[0].Name
        );

        System.assertEquals(
            UserInfo.getUserId(),
            results[0].Assigned_User__c
        );

        System.assertEquals(
            2026,
            results[0].Objective_Year__c
        );
    }


    @IsTest
    static void testGetKeyResults() {

        Objective__c testObjective = new Objective__c(
            Name = 'Standard Measurements Objective',
            Assigned_User__c = UserInfo.getUserId(),
            Objective_Year__c = 2026
        );

        insert testObjective;


        // CALLS
        Key_Result__c testCallKeyResult = new Key_Result__c(
            Name = 'Test Call Key Result',
            Objective__c = testObjective.Id,
            Target__c = 50,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Calls',
            Measurement_Criteria__c = 'All'
        );


        // EVENTS
        Key_Result__c testEventKeyResult = new Key_Result__c(
            Name = 'Test Event Key Result',
            Objective__c = testObjective.Id,
            Target__c = 20,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Events',
            Measurement_Criteria__c = 'All'
        );


        // OPPORTUNITIES
        Key_Result__c testOpportunityKeyResult = new Key_Result__c(
            Name = 'Test Opportunity Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Opportunities',
            Measurement_Criteria__c = 'New Business'
        );


        // CONTRACTS
        Key_Result__c testContractKeyResult = new Key_Result__c(
            Name = 'Test Contract Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Contracts',
            Measurement_Criteria__c = 'New Business'
        );


        // LEADS
        Key_Result__c testLeadKeyResult = new Key_Result__c(
            Name = 'Test Lead Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Leads',
            Measurement_Criteria__c = 'Web'
        );


        insert new List<Key_Result__c>{
            testCallKeyResult,
            testEventKeyResult,
            testOpportunityKeyResult,
            testContractKeyResult,
            testLeadKeyResult
        };


        // CALL
        Task testCall = new Task(
            Subject = 'Test Call',
            Status = 'Completed',
            Priority = 'Normal',
            TaskSubtype = 'Call',
            Key_Result__c = testCallKeyResult.Id
        );

        insert testCall;


        // EVENT
        Event testEvent = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now().addHours(-2),
            EndDateTime = System.now().addHours(-1),
            Key_Result__c = testEventKeyResult.Id
        );

        insert testEvent;


        // OPPORTUNITY
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Key_Result__c = testOpportunityKeyResult.Id
        );

        insert testOpportunity;


        // CONTRACT
        Account testAccount = new Account(
            Name = 'Test Contract Account'
        );

        insert testAccount;

        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft',
            Contract_Type__c = 'New Business',
            Key_Result__c = testContractKeyResult.Id
        );

        insert testContract;

        testContract.Status = 'Activated';

        update testContract;


        // LEAD
        String leadStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = false
            LIMIT 1
        ].MasterLabel;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Web Lead',
            Company = 'Test Web Company',
            LeadSource = 'Web',
            Status = leadStatus,
            Key_Result__c = testLeadKeyResult.Id
        );

        insert testLead;


        Test.startTest();

        List<Key_Result__c> results =
            ObjectiveController.getKeyResults(testObjective.Id);

        Test.stopTest();


        System.assertEquals(5, results.size());


        for (Key_Result__c keyResult : results) {

            if (keyResult.Id == testCallKeyResult.Id) {
                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == testEventKeyResult.Id) {
                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == testOpportunityKeyResult.Id) {
                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == testContractKeyResult.Id) {
                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == testLeadKeyResult.Id) {
                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }
        }
    }


    @IsTest
    static void testGetKeyResults_CustomMeasurements() {

        Objective__c testObjective = new Objective__c(
            Name = 'Custom Measurements Objective',
            Assigned_User__c = UserInfo.getUserId(),
            Objective_Year__c = 2026
        );

        insert testObjective;
        
        // SURVEY KEY RESULT

        Key_Result__c surveyKeyResult = new Key_Result__c(
            Name = 'Survey Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Surveys',
            Measurement_Criteria__c = 'All'
        );
      
        // REVIEW KEY RESULT
  
        Key_Result__c reviewKeyResult = new Key_Result__c(
            Name = 'Review Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Reviews',
            Measurement_Criteria__c = 'All'
        );

        // GOOGLE REVIEW KEY RESULT

        Key_Result__c googleReviewKeyResult = new Key_Result__c(
            Name = 'Google Review Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Google Reviews',
            Measurement_Criteria__c = 'All'
        );

        // CASE STUDY KEY RESULT

        Key_Result__c caseStudyKeyResult = new Key_Result__c(
            Name = 'Case Study Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Case Studies',
            Measurement_Criteria__c = 'All'
        );


        insert new List<Key_Result__c>{
            surveyKeyResult,
            reviewKeyResult,
            googleReviewKeyResult,
            caseStudyKeyResult
        };
            
        // SURVEY

        String surveyType =
            getFirstPicklistValue(
                OKR_Survey__c.Survey_Type__c
            );

        OKR_Survey__c survey = new OKR_Survey__c(
            Name = 'Test Survey',
            Key_Result__c = surveyKeyResult.Id,
            Survey_Date__c = Date.today(),
            Score__c = 5,
            Survey_Type__c = surveyType,
            Notes__c = 'Test survey for Apex coverage'
        );

        insert survey;

        // REVIEW
  
        String reviewType =
            getFirstPicklistValue(
                OKR_Review__c.Review_Type__c
            );

        OKR_Review__c review = new OKR_Review__c(
            Name = 'Test Review',
            Key_Result__c = reviewKeyResult.Id,
            Review_Dates__c = Date.today(),
            Rating__c = 5,
            Review_Type__c = reviewType,
            Comments__c = 'Test review for Apex coverage'
        );

        insert review;

        // GOOGLE REVIEW
      
        OKR_Google_Review__c googleReview =
            new OKR_Google_Review__c(
                Name = 'Test Google Review',
                Key_Result__c = googleReviewKeyResult.Id,
                Review_Date__c = Date.today(),
                Reviewer_Name__c = 'Test Reviewer',
                Google_Rating__c = 5,
                Comments__c = 'Test Google review for Apex coverage'
            );

        insert googleReview;

        // CASE STUDY

        String caseStudyIndustry =
            getFirstPicklistValue(
                OKR_Case_Study__c.Industry__c
            );

        OKR_Case_Study__c caseStudy =
            new OKR_Case_Study__c(
                Name = 'Test Case Study',
                Key_Result__c = caseStudyKeyResult.Id,
                Case_Study_Date__c = Date.today(),
                Customer_Name__c = 'Test Customer',
                Description__c = 'Test case study for Apex coverage',
                Industry__c = caseStudyIndustry
            );

        insert caseStudy;


        // RUN CONTROLLER

        Test.startTest();

        List<Key_Result__c> results =
            ObjectiveController.getKeyResults(testObjective.Id);

        Test.stopTest();

        // VERIFY
        
        System.assertEquals(4, results.size());


        for (Key_Result__c keyResult : results) {

            if (keyResult.Id == surveyKeyResult.Id) {

                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == reviewKeyResult.Id) {

                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == googleReviewKeyResult.Id) {

                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }

            if (keyResult.Id == caseStudyKeyResult.Id) {

                System.assertEquals(
                    1,
                    keyResult.Completed_Target__c
                );
            }
        }
    }
}