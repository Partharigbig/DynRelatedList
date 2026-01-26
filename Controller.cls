public with sharing class MedicalConditionsMobileCtrl {
 
    @AuraEnabled(cacheable=true)
    public static Id getRecordTypeIdByDeveloperName(String sobjectApiName, String developerName) {
        if (String.isBlank(sobjectApiName) || String.isBlank(developerName)) return null;
        try {
            RecordType rt = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = :sobjectApiName AND DeveloperName = :developerName
                LIMIT 1
            ];
            return rt != null ? rt.Id : null;
        } catch (Exception e) {
            return null;
        }
    }
 
    // NOTE: nonce param lets us bust cache on refresh
    @AuraEnabled(cacheable=true)
    public static List<SObject> getChildren(
        Id parentId,
        String childObjectApiName,
        String parentLookupFieldApiName,
        List<String> fieldApiNames,
        Id recordTypeId,
        Integer limitSize,
        Integer nonce
    ) {
        if (parentId == null || String.isBlank(childObjectApiName) || String.isBlank(parentLookupFieldApiName)) {
            return new List<SObject>();
        }
        Set<String> fields = new Set<String>();
        if (fieldApiNames != null) fields.addAll(fieldApiNames);
        fields.add('Id'); fields.add('Name'); fields.add('RecordTypeId'); fields.add('RecordType.Name');
 
        String soql =
            'SELECT ' + String.join(new List<String>(fields), ',') +
            ' FROM ' + childObjectApiName +
            ' WHERE ' + parentLookupFieldApiName + ' = :parentId' +
            (recordTypeId == null ? '' : ' AND RecordTypeId = :recordTypeId') +
            ' ORDER BY CreatedDate DESC' +
            (limitSize != null && limitSize > 0 ? ' LIMIT :limitSize' : '');
 
        return Database.query(soql);
    }
 
    @AuraEnabled(cacheable=true)
    public static Integer countChildren(
        Id parentId,
        String childObjectApiName,
        String parentLookupFieldApiName,
        Id recordTypeId
    ) {
        if (parentId == null || String.isBlank(childObjectApiName) || String.isBlank(parentLookupFieldApiName)) {
            return 0;
        }
        String soql = 'SELECT COUNT() FROM ' + childObjectApiName +
                      ' WHERE ' + parentLookupFieldApiName + ' = :parentId' +
                      (recordTypeId == null ? '' : ' AND RecordTypeId = :recordTypeId');
        return (Integer)Database.countQuery(soql);
    }
}
