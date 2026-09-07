@IsTest
private class ObjectiveControllerTest {

    @IsTest
    static void testGetObjectives() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Objective__c testObjective = new Objective__c(
            Name = 'Test Objective',
            Assigned_User__c = testUser.Id,
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
            testUser.Id,
            results[0].Assigned_User__c
        );

        System.assertEquals(
            2026,
            results[0].Objective_Year__c
        );
    }

    @IsTest
    static void testGetKeyResults() {

        User testUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Objective__c testObjective = new Objective__c(
            Name = 'Test Objective',
            Assigned_User__c = testUser.Id,
            Objective_Year__c = 2026
        );

        insert testObjective;

        Key_Result__c testCallKeyResult = new Key_Result__c(
            Name = 'Test Call Key Result',
            Objective__c = testObjective.Id,
            Target__c = 50,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Calls',
            Measurement_Criteria__c = 'All'
        );

        Key_Result__c testEventKeyResult = new Key_Result__c(
            Name = 'Test Event Key Result',
            Objective__c = testObjective.Id,
            Target__c = 20,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Events',
            Measurement_Criteria__c = 'All'
        );

        Key_Result__c testOpportunityKeyResult = new Key_Result__c(
            Name = 'Test Opportunity Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Opportunities',
            Measurement_Criteria__c = 'New Business'
        );

        Key_Result__c testContractKeyResult = new Key_Result__c(
            Name = 'Test Contract Key Result',
            Objective__c = testObjective.Id,
            Target__c = 10,
            Completed_Target__c = 0,
            Measurement_Type__c = 'Contracts',
            Measurement_Criteria__c = 'New Business'
        );

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

        Task testCall = new Task(
            Subject = 'Test Call',
            Status = 'Completed',
            Priority = 'Normal',
            TaskSubtype = 'Call',
            Key_Result__c = testCallKeyResult.Id
        );

        insert testCall;

        Event testEvent = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now().addHours(-2),
            EndDateTime = System.now().addHours(-1),
            Key_Result__c = testEventKeyResult.Id
        );

        insert testEvent;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Key_Result__c = testOpportunityKeyResult.Id
        );

        insert testOpportunity;

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
}