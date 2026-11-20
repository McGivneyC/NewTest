@IsTest
private class DeploymentResultControllerTest {
    @IsTest
    static void testGetDeploymentResultJson_nullRecordId() {
        String result = DeploymentResultController.getDeploymentResultJson(null);
        System.assertEquals(null, result, 'Expected null when recordId is null');
    }

    @IsTest
    static void testGetDeploymentResultJson_noAttachments() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Test.startTest();
        String result = DeploymentResultController.getDeploymentResultJson(acc.Id);
        Test.stopTest();
        System.assertEquals(null, result, 'Expected null when no files are attached');
    }

    @IsTest
    static void testGetDeploymentResultJson_withMatchingFile() {
        Account acc = new Account(Name = 'Test Account With File');
        insert acc;
        String jsonContent = '{"status":"Succeeded","numberComponentsDeployed":10,"numberComponentsTotal":10}';
        ContentVersion cv = new ContentVersion();
        cv.Title = 'deploymentResult';
        cv.PathOnClient = 'deploymentResult.json';
        cv.VersionData = Blob.valueOf(jsonContent);
        cv.IsMajorVersion = true;
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = acc.Id;
        cdl.ShareType = 'V';
        insert cdl;
        Test.startTest();
        String result = DeploymentResultController.getDeploymentResultJson(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected JSON content to be returned');
        System.assert(result.contains('Succeeded'), 'Expected result to contain Succeeded status');
    }

    @IsTest
    static void testGetDeploymentResultJson_noMatchingFileName() {
        Account acc = new Account(Name = 'Test Account No Match');
        insert acc;
        ContentVersion cv = new ContentVersion();
        cv.Title = 'someOtherFile';
        cv.PathOnClient = 'someOtherFile.json';
        cv.VersionData = Blob.valueOf('{"data":"test"}');
        cv.IsMajorVersion = true;
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCv.ContentDocumentId;
        cdl.LinkedEntityId = acc.Id;
        cdl.ShareType = 'V';
        insert cdl;
        Test.startTest();
        String result = DeploymentResultController.getDeploymentResultJson(acc.Id);
        Test.stopTest();
        System.assertEquals(null, result, 'Expected null when no file matches deploymentResult naming');
    }
}