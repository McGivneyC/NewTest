public with sharing class DeploymentResultController {
    @AuraEnabled(cacheable=true)
    public static String getDeploymentResultJson(Id recordId) {
        if (recordId == null) return null;
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            ORDER BY SystemModstamp DESC
        ];
        if (links.isEmpty()) return null;
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            docIds.add(link.ContentDocumentId);
        }
        List<ContentVersion> versions = [
            SELECT VersionData, Title, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND IsLatest = true
            AND (Title LIKE '%deploymentResult%' OR Title LIKE '%DeploymentResult%')
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];
        if (versions.isEmpty()) return null;
        return versions[0].VersionData.toString();
    }
}